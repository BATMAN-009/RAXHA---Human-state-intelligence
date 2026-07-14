# Chapter B2 — Swift & the Apple Development Stack

> **Paired with:** A-1.2 (Gyroscope). The gyro taught you that evidence must be summoned cheaply and precisely; Swift is where you write the code that does the summoning on Apple hardware. Taught under the Principal Architect contract: why it exists → internals → OS reality → latency/battery/security → failure modes → RAXHA production shape.

---

## 1. Why Swift exists

Until 2014, Apple platforms ran on **Objective-C** — a 1980s object layer over C. It had two properties fatal to safety-critical work: rampant undefined behavior inherited from C (null dereferences, buffer overruns) and dynamic message-passing that defers many errors to runtime.

**Swift** (Chris Lattner's team at Apple, begun ~2010, unveiled 2014, open-sourced 2015) was designed to keep C-level performance while making whole bug classes *unrepresentable*:

- **Optionals:** nullability in the type system — the compiler forces you to handle "no value." For RAXHA: "sensor data absent" is a typed state you must handle, not a crash at 3 a.m.
- **Value types + Copy-on-Write:** structs/enums with no shared mutable state by default.
- **Exhaustive `switch` over enums:** the compiler proves you handled every state — tailor-made for our escalation FSM. Add a state, and every file that must care *fails to compile* until it does.
- **Swift 6 (2024): compile-time data-race safety.** The concurrency checker proves that mutable state isn't accessed from two threads at once (`Sendable`, actor isolation). For a system where a sensor callback, a BLE delegate, and a UI touch can race on the same FSM, this is not a nicety — it eliminates the exact class of heisenbug that eats safety systems.

**The doctrine connection:** Swift's design philosophy — *make invalid states unrepresentable, prove correctness at compile time* — is the language-level mirror of Decision #10 (architecture before code).

---

## 2. Internals that matter for RAXHA

### 2.1 ARC, not garbage collection
Swift uses **Automatic Reference Counting**: deallocation happens deterministically the instant the last reference dies. No GC pauses. For a latency-budgeted pipeline (<100 ms inference, <50 ms SOS generation) determinism matters: your p99 doesn't grow a garbage-collector tail.

The cost: **retain cycles**. Two objects strongly referencing each other never die. The classic wearable-app leak: a sensor manager strongly holds a closure that strongly holds `self`. Fix with `weak`/`unowned` captures — and *test* with the Memory Graph Debugger, because a slow leak in an always-on app is a guaranteed eventual OS kill.

### 2.2 Concurrency: GCD → structured concurrency
- Historical layer: **Grand Central Dispatch** (queues, 2009) — still underneath everything.
- Modern layer: **async/await + structured concurrency + actors** (Swift 5.5, 2021).
- **Actors** serialize access to their state. `RiskEngine` as an actor means sensor batches, config updates, and queries physically cannot interleave mid-update.
- **The main-thread law:** UI on the main actor, *nothing else* on it. iOS's watchdog kills apps whose main thread hangs (the infamous `0x8badf00d` — "ate bad food" — termination). A safety app being executed by the OS for a blocked main thread is an unforgivable architecture failure: sensor and risk work live on background executors, always.
- **Combine vs async streams:** Combine (2019, reactive pipelines) still powers many APIs; new RAXHA code should prefer `AsyncSequence`/`AsyncStream` for sensor pipelines — simpler, structured, cancellation-correct. Interop is easy; religious wars are not required.

### 2.3 SwiftUI
Declarative UI (2019): the view is a function of state. For RAXHA the argument is *auditable correctness*: the incident screen (`COUNTDOWN` → big cancel button + timer) is a pure render of the FSM state — you can unit-test "state X renders cancel UI" without a device. Combined with **ActivityKit Live Activities** (lock-screen incident card) and **WidgetKit**, the response surface stays visible without the app being foreground.

---

## 3. The OS reality: background execution (the chapter's hard core)

Everything in B1 §3 now gets its Apple-specific mechanics. Memorize the hierarchy of *what keeps code running*:

| Mechanism | What it gives | What it does NOT give |
|---|---|---|
| Foreground app | Everything | Users lock their phones |
| **Background modes** (location, audio, BLE accessory) | Continued execution for the declared purpose | App Review scrutiny; battery cost; misuse = rejection |
| **Silent push (`content-available`)** | Wake app briefly on server signal | *Not guaranteed* — coalesced, budgeted, dropped under low power |
| **BGTaskScheduler** (`BGAppRefreshTask`, `BGProcessingTask`) | Deferred batch work | Runs when *the system* chooses — hours of slack; never for emergencies |
| **HealthKit background delivery** | Wake on new health samples | Follows system scheduling/entitlements — **not instant-guaranteed [V]**, per doctrine §4 |
| **CoreLocation** significant-change / region monitoring | App relaunch on location events, even after termination | Coarse granularity |
| **watchOS `HKWorkoutSession`** | Sustained runtime + high-rate sensors on watch | Semantically a workout; battery; not a 24/7 answer |
| **watchOS `WKExtendedRuntimeSession`** | Bounded sessions for specific scenarios | Time-limited |
| **`CMFallDetectionManager`** (entitlement) | *Apple's* Tier-0/1 delivering fall events, even backgrounded | You don't see raw data; you trust their detector |

**The architectural conclusion (unchanged from B1, now with mechanisms):** on Apple hardware RAXHA does not fight for continuous background sensing — it *composes the sanctioned primitives*: platform fall events + workout sessions during armed high-risk modes + location wakeups + push-driven coordination + `CMSensorRecorder` for retrospective accelerometer forensics. The phone side runs the durable FSM; **timers are timestamps + re-registered wakeups, never in-memory** (your Q2 answer, now in its native habitat: `UserDefaults`/file/SQLite for state, local notifications and BGTasks re-registered on launch, and reconciliation-on-wake computing remaining time from the persisted `StartedAt`).

**Latency truth-telling:** an armed incident in progress keeps the app *alive* (foreground on watch, Live Activity + location session on phone), so the <500 ms pipeline applies to the active path. The *cold* path — something the OS must wake you for — carries seconds of OS-scheduled slack, which is why Tier-0 detection lives in hardware/OS layers that never sleep, not in your app process.

---

## 4. Security on-platform

- **Keychain** for credentials/tokens; **Secure Enclave** for keys that never leave silicon; **Data Protection classes** — a `whenUnlocked`-protected FSM state file is unreadable exactly when reboot-recovery needs it. `afterFirstUnlock` is better but **still insufficient for the critical case**: its true semantics are "readable after the first unlock *following boot*" — a phone that reboots mid-incident with an unconscious user is *never unlocked*, and the state stays encrypted. *(Credit: this gap was surfaced by the learner's Competency-2 gate answer, 2026-07-13.)* The complete defense: (a) **split by sensitivity** — the minimal FSM journal (event ID, state, timestamps; no health data) lives in `FileProtectionType.none` storage, defensible because it contains nothing sensitive, while rich payloads stay protected; (b) **distribute the state** — the server-side FSM mirror is a dead-man's switch: a heartbeat that vanishes mid-incident triggers cloud-side escalation regardless of what the phone can read. Durable is not enough; safety state must be *distributed* (tier-autonomy invariant, B1 §2).
- **App Transport Security** (TLS enforced), certificate pinning for the alert channel.
- Entitlements as security boundary: fall-detection entitlement, HealthKit scopes, critical-alert notification permission (`critical-alert` push type bypasses mute/Do-Not-Disturb — the responder-side must request it; requires Apple approval **[V]**).

---

## 5. Failure modes (Apple-flavored)

| Failure | Cause | Defense |
|---|---|---|
| App killed mid-incident | Memory pressure, watchdog, user swipe-kill | Durable FSM + relaunch triggers (location, push, notification actions); Live Activity survives the process |
| Main-thread hang → `0x8badf00d` kill | Sync I/O or heavy work on main actor | Strict actor architecture; hang detection in CI (Instruments) |
| Silent push never arrives | Budgets, Low Power Mode | Never make safety depend on silent push; it's an optimization only |
| Retain-cycle leak → slow death | Closure captures in long-lived sensor managers | `weak self` discipline; leak tests in CI |
| State file unreadable after reboot-while-locked | Wrong Data Protection class | `afterFirstUnlock` for FSM state (see §4) |
| Works in debug, dies in TestFlight | Debugger keeps apps alive artificially | Test background behavior on release builds, device untethered |

---

## 6. RAXHA production shape (iOS/watchOS)

```
RaxhaKit/                        ← SwiftPM workspace; platform-free core first
├─ RiskEngineCore/               pure Swift, zero Apple imports
│   ├─ SignalProcessing/         filters, features (testable on Linux CI!)
│   ├─ Fusion/                   event-window fusion logic
│   ├─ RiskScoring/
│   └─ EscalationFSM/            states, transitions, write-ahead log protocol
├─ PersistenceKit/               SQLite (e.g. GRDB); FSM journal; outbox queue
├─ SensorAdapters/               CoreMotion/HealthKit/CMFallDetection wrappers
│                                (protocol-based → replay harness injects here)
├─ ConnectivityKit/              WatchConnectivity + URLSession outbox uploader
├─ RaxhaWatch App/               SwiftUI, workout-session controller, local alarm
└─ Raxha iOS App/                SwiftUI, Live Activity, countdown UI, contacts
```

**The two structural laws:**
1. **`RiskEngineCore` imports nothing Apple.** Pure Swift → runs in plain CI containers → the replay harness (recorded sensor traces → assert FSM outcome) needs no simulator, no device, no Apple. This is Decision #10 made physical.
2. **Every OS surface is behind a protocol.** `FallEventSource`, `MotionSource`, `Clock`, `AlertTransport` — production wires CoreMotion et al.; tests wire recordings and fake clocks (how you unit-test "reboot at T+10 s into COUNTDOWN" in milliseconds).

**Real-world anchors:** Apple's own health stack is Swift/Objective-C native with detection below the app layer **[V/I]**; WHOOP has publicly discussed its large-scale Swift/SwiftUI iOS app **[V]**; no serious safety/health wearable product ships its critical path cross-platform **[I, strongly supported]**.

---

## 7. Mastery Test — B2

1. Why does ARC (vs garbage collection) matter for a latency-budgeted pipeline, and what discipline does ARC demand in return from long-lived sensor managers?
2. Explain compile-time data-race safety in Swift 6 and give a concrete RAXHA race it prevents (name the two threads and the shared state).
3. Rank the background-execution mechanisms by *trustworthiness for an emergency path*, and justify why silent push is near the bottom.
4. The FSM state file was written with the `whenUnlocked` protection class. Describe the exact failure scenario this creates, referencing your own Q2 (reboot-during-countdown) answer.
5. Why must `RiskEngineCore` contain zero `import CoreMotion` / `import HealthKit`? Name the two concrete capabilities this buys.
6. Design the "armed walking-alone mode" on watchOS: which session API keeps you running, what sensors at what rates, what the battery cost story is, and what happens when the session hits its limits.

---

## 8. Founder Intelligence

**The strategic reading of this chapter:** on Apple's platform, *Apple is your landlord.* Entitlements (fall detection, critical alerts), App Review, and background-execution budgets are granted, not owned — and Apple can Sherlock you (absorb your feature into the OS) at any WWDC. **Mitigations that are strategy, not code:** (1) the moat lives in the cross-platform response network Apple won't build; (2) the fall-detection entitlement and critical-alert approval are *earned assets* — treat the Apple relationship as a business function; (3) `RiskEngineCore` being pure Swift is also an exit hedge — the detection IP is portable.

**Why native is a founder decision, not just an engineering one:** hiring (senior Swift/Kotlin engineers exist; senior "Flutter-for-safety-critical" engineers do not), App Review risk (health apps using non-native health APIs draw scrutiny), and acquisition optics (an acquirer's due diligence on a safety product will audit the critical path — cross-platform there is a red flag). ✅ WHOOP publicly discusses its native Swift/SwiftUI app; 🟡 no serious health wearable ships a cross-platform critical path; 🔴 exact internal stack splits.

**Research/opportunity gap:** reproducible background-execution benchmarking across iOS versions and Low Power Mode states — the data every health-app founder needs and nobody publishes. A test-harness product (or paper) lives here.

**Reverse-engineering ledger:** ✅ documented API behaviors (BGTask scheduling windows, workout-session sensor rates); 🟡 exact silent-push budget heuristics; 🔴 watchdog thresholds' precise values. Design to documented guarantees only — a 🟡 that works today is an outage next iOS version.

## 9. Design Review (panel highlights)

- **Apple reviewer:** "You request the fall-detection entitlement, critical alerts, *and* background location. Justify each against your stated user benefit or expect rejection — and your privacy nutrition label must match the data-plane doctrine exactly."
- **Security researcher:** "FSM state in `UserDefaults`? That's unencrypted plist territory. Sensitive state goes in protected files/Keychain with `afterFirstUnlock` — you wrote the rule, follow it."
- **Investor:** "Your Apple-platform feature depends on an entitlement Apple grants competitors too. What's proprietary?" *(Answer: nothing at Tier 0/1 on iOS — by design; the ledger shows the moat lives above.)*

## 10. Constraint Exercise

Apple grants you `CMFallDetectionManager` but **rejects** your critical-alert entitlement request (first application usually is). The alert must still reliably reach a sleeping family member's iPhone at 3 a.m. Design the notification strategy within what iOS actually permits — and write the two-paragraph re-application to Apple making the case for critical alerts.

---

## 11. Chief Scientist's Verdict

**Confidence Ledger:** Swift 6 compile-time data-race safety eliminates that bug class in checked code — ★★★★★ (language-level guarantee). "Native is required for the safety-critical path" — ★★★★☆ (strong industry practice ✅/🟡; no controlled study exists, honestly — the evidence is converging practice plus mechanism-level reasoning). "Silent push is unreliable for time-critical wakeups" — ★★★★★ (documented platform behavior). "watchOS permits no third-party continuous background sensing" — ★★★★★ today (✅ documented), 🟡 forever — platform rules move yearly; re-verify each WWDC.

**TRL:** Swift/SwiftUI/async-await for production health apps — 9. `CMFallDetectionManager` as third-party integration surface — 8 (shipping API; entitlement-gated). RAXHA's protocol-injected replay harness — 7 as described (standard technique, needs building). Live Activities as incident surface — 8.

**Roadmap Placement:** *MVP:* platform fall events + durable FSM + Live Activity incident UI + `afterFirstUnlock` persistence. *V2:* armed-mode workout-session sensing, critical-alerts entitlement (responder side). *Research Lab:* own iOS-side detection models (only meaningful if Apple's event granularity proves insufficient — measure first). *Never Build:* jailbreak-adjacent or private-API sensing workarounds (App Review death + trust death), safety logic in a cross-platform layer (doctrine §1.1).

**Competitor Failure Analysis (sourced):** The App Store's history of health apps rejected or purged for background-execution abuse and privacy-label mismatches (documented review-guideline enforcement) — the failure mode is *fighting the platform*. Facebook/Meta's documented background-location controversies — the reputational template for what happens when "always-on" meets ambiguous consent; RAXHA's consent UX must be un-ambiguous by design.

**Kill Criteria:** If the fall-detection entitlement is denied and appeals fail → the iOS product pivots to crash + manual SOS + phone-context; state this plan *before* building dependence. If Apple ships RAXHA's full response layer natively (family fall notifications already exist in basic form ✅) → the differentiation test is: do families *choose* RAXHA's experience over built-in within 30 days of trial? Below ~20% preference, the iOS-first strategy dies and Android/elder-care B2B leads.

**Historical Failures (Historian's ledger):**
- **The Sherlocked** — Duet/Luna (killed by Sidecar), f.lux (Night Shift), third-party sleep trackers (native watchOS sleep tracking): the recurring pattern of apps whose entire value sat where Apple was about to build. Axis: platform risk. RAXHA's §18 mitigation is structural — the moat must live where Apple structurally won't go (cross-platform family network).
- **Private-API health apps purged from the App Store** — documented enforcement waves. Axis: platform compliance. Lesson: the sanctioned-primitives-only rule (§3) is not conservatism; it's survival.
- **Basis, again** (see 1.1) — as an Intel subsidiary it also shows acquisition doesn't rescue a product whose reliability story broke. A safety product carries its reliability record like a credit score.

---

*Competency 3 pairing: A-1.4 (IMU & calibration) + B3 (Kotlin & the Android/Wear OS stack).*
