# Chapter B3 — Kotlin & the Android/Wear OS Stack

> **Paired with:** A-1.3/1.4 (Magnetometer, IMU & calibration). That chapter taught the gated-trust pattern for sensors; this one teaches the gated-trust pattern for an *operating system* — because on Android, RAXHA owns more of the stack and more of the risk (B1 §3), and the OS's promises must be cross-examined exactly like a magnetometer's. Includes the Android mirror of the `whenUnlocked` failure you just diagnosed — it has a name here: **Direct Boot**.

---

## 1. Why Kotlin exists

Android's original language was Java — specifically, a Java frozen for years by litigation and API-level fragmentation, dragging null-pointer exceptions (Tony Hoare's "billion-dollar mistake") through every app. **Kotlin** (JetBrains, released 1.0 in 2016; Google first-class support 2017, "Kotlin-first" 2019) is to Android what Swift is to iOS, with eerily parallel choices:

- **Null safety in the type system:** `String` vs `String?` — the compiler forces handling of absence. Same safety class as Swift optionals; same RAXHA payoff (missing sensor data is a typed state, not a 3 a.m. crash).
- **Data classes, sealed classes, exhaustive `when`:** a `sealed class EscalationState` makes the FSM compiler-checked — add a state, and every `when` that must handle it fails to compile. The direct Kotlin twin of Swift's exhaustive `switch`.
- **Coroutines + Flow (structured concurrency):** `suspend` functions ≈ `async/await`; `Flow` ≈ `AsyncSequence`; `StateFlow` ≈ observable state; coroutine scopes tied to lifecycles give automatic cancellation. The concurrency *model* you learned in B2 transfers almost one-to-one — learn the mapping once, and you maintain two native codebases with one mental model. That mapping is the founder-level answer to "isn't two native apps twice the work?" — the *thinking* is shared; only the typing is doubled.
- **Interop:** Kotlin compiles to JVM bytecode and calls all Java APIs — the entire Android SDK and 15 years of libraries work unchanged.

---

## 2. The Android execution model — what you're actually running on

- Every app runs in its own process, forked from Zygote, sandboxed by UID. The OS kills processes freely under memory pressure, **and your process must assume it can die between any two lines of code** — Android developers internalize what iOS developers learn late: *process death is not an edge case, it's the weather.*
- **Lifecycles:** Activities/Services are components the OS creates and destroys; `ViewModel` + `SavedStateHandle` survive configuration changes and (partially) process death — but the durable FSM journal (Competency 1) remains the only real persistence. Nothing you learned about write-ahead state gets relaxed here; Android just kills you more often, making the discipline pay off sooner.
- **Jetpack Compose** (2021, stable): declarative UI, state-driven — the Kotlin twin of SwiftUI, including **Compose for Wear OS**. Same auditability argument: incident UI = pure function of FSM state.

---

## 3. Background execution — the adversary, mapped precisely

The Android background-mechanism table, ranked like B2 §3 (trustworthiness for an emergency path):

| Mechanism | What it gives | The catch |
|---|---|---|
| **Foreground Service** (with persistent notification) | Genuine continuous execution | Android 14+ requires a declared *type* (`health`, `location`, ...) with permission prerequisites; user-visible; OEM killers still stalk it |
| **Health Services (Wear OS)** | Detection offloaded to the low-power MCU — passive monitoring, exercise tracking, **fall detection events on supported watches** | You get *events*, not raw streams, at the platform's granularity — the Wear OS mirror of `CMFallDetectionManager` |
| **`AlarmManager` exact alarms** | Wake at a precise time — the countdown-deadline primitive | Android 12+: `SCHEDULE_EXACT_ALARM` permission, revocable; Android 14: denied by default for most apps — **but `USE_EXACT_ALARM` is granted for calendar/alarm-class apps, and safety timing is your App-Review-style argument to make** |
| **High-priority FCM push** | Wake the app from Doze for time-critical messages | Quota-limited if abused; delivery not guaranteed on aggressive OEMs |
| **`WorkManager`** | Deferred, constraint-aware, guaranteed-eventually work | *Eventually* — batching windows of minutes to hours; never for the emergency path |
| **`BOOT_COMPLETED` receiver** | Relaunch after reboot — your FSM-recovery entry point | Delayed on some OEMs; requires the app wasn't force-stopped |
| **Doze / App Standby buckets** | (The adversary itself) network and job deferral in idle windows | Maintenance windows only; exact alarms and high-priority FCM are the sanctioned punch-throughs |
| **OEM battery managers** (several major brands) | (The unsanctioned adversary) kill services beyond AOSP rules | ✅ extensively documented by the developer community (dontkillmyapp.com); per-brand allowlist flows exist; **gap telemetry is the only honest defense** |

**The RAXHA Android composition:** Health Services on the watch (Tier 0/1) → foreground service of type `health`/`location` on the phone during incidents and armed modes → exact alarms for countdown deadlines → `BOOT_COMPLETED` + on-launch reconciliation for recovery → high-priority FCM as the cloud's wake channel → battery-optimization exemption requested with the safety justification (a legitimate, documented use).

---

## 4. Direct Boot — the Android mirror of your `whenUnlocked` answer

After a reboot, before the user's first unlock, Android is in **Direct Boot mode**: credential-encrypted (CE) storage — the default — is *locked*, exactly like iOS files before first unlock. Your Competency-2 scenario (reboot mid-COUNTDOWN, unconscious user, never unlocked) kills a naive Android app identically.

The sanctioned escape: **device-encrypted (DE) storage** — `context.createDeviceProtectedStorageContext()` — readable immediately at boot, encrypted with a device key rather than the user's credential. A **Direct Boot aware** component (`android:directBootAware="true"`) can receive `LOCKED_BOOT_COMPLETED` and run *before first unlock*.

The design is therefore the same split you derived on iOS, with better primitives:
- **DE storage:** the minimal FSM journal — event ID, state, timestamps, alert-sent flags. No health payloads, no contact details beyond what alerting strictly needs.
- **CE storage:** everything sensitive.
- **Cloud dead-man's switch:** unchanged — the server-side mirror escalates if the phone's mid-incident heartbeat vanishes, whatever the phone can or cannot read.

That one paragraph is why this chapter is paired where it is: you *derived* the pattern under examination pressure on iOS; Android hands you first-class API for it. Cross-platform mastery is recognizing the same invariant wearing two SDKs.

---

## 5. Persistence & data layer

- **Room** (SQLite + compile-checked queries + Flow observation) for the FSM journal and outbox queue — the write-ahead log from B1 §4 becomes a Room table with an `events` append-only design.
- **DataStore** (typed, coroutine-native) for configuration; `SharedPreferences` is legacy.
- Both can be opened against the DE context for the Direct Boot subset. **Test the locked path in CI:** `adb reboot` + assertions before unlock is an automatable scenario on emulators.

## 6. Wear OS specifics

- **Health Services** for passive data + exercise sessions; **Ongoing Activity API** for the persistent incident surface (the Wear twin of Live Activities); **tiles/complications** for one-glance arming.
- **Watch↔phone:** the Data Layer API (`MessageClient`, `DataClient` — sync semantics with offline buffering) over Bluetooth; the store-and-forward queue B1 §5 demanded is partially provided by the platform, but delivery latency is not guaranteed — the watch must still be able to escalate alone (LTE watches; doctrine §2 amendment).
- Wear OS hardware is heterogeneous (unlike the Apple Watch monoculture): sensor availability, Health Services capabilities, and battery vary per device — **capability detection at runtime, never assumptions**, and the coverage telemetry must be segmented by device model.

## 7. Architecture — the Kotlin twin of RaxhaKit

```
raxha-android/
├─ core-riskengine/        pure Kotlin, zero Android imports (JVM CI, replay harness)
│   ├─ signal/  fusion/  scoring/  fsm/
├─ core-persistence/       Room; DE/CE split; outbox
├─ sensor-adapters/        HealthServices / SensorManager behind interfaces
├─ connectivity/           DataLayer + FCM + REST outbox uploader
├─ app-wear/               Compose for Wear OS; ongoing activity; local alarm
└─ app-phone/              Compose; countdown UI; contacts; foreground service
```
Same two structural laws as B2: the risk engine imports no OS; every OS surface is a Hilt-injected interface so recorded traces and fake clocks drive CI. One replay-test corpus, two platforms consuming it — **the test data is shared even though the code isn't.**

## 8. Failure modes (Android-flavored)

| Failure | Cause | Defense |
|---|---|---|
| Service dead by morning on brand X | OEM battery manager | Per-OEM exemption flows at onboarding; gap telemetry; degraded-protection UX |
| Countdown deadline never fired | Exact-alarm permission revoked / Doze deferral | Permission monitoring + re-request UX; FCM backup deadline from the cloud FSM |
| FSM unreadable after reboot-while-locked | Journal in CE storage | DE storage + `directBootAware` receiver (§4) |
| Notification invisible | Android 13+ `POST_NOTIFICATIONS` runtime permission denied | Onboarding gate: no notification permission → protection is not armable; say so |
| Works on Pixel, dies on brand X | OEM divergence from AOSP | Device-segmented telemetry; top-OEM physical test rack; the B1 kill criterion (95% protected-hours) decides |
| Force-stopped app never revives | User or OEM "app killed" state disables all receivers | Detect via heartbeat absence server-side; re-engagement push/SMS to the *user* ("protection is off") |

## 9. Founder Intelligence

**The strategic frame:** Android is where RAXHA owns its destiny — no entitlement gatekeeper, real background execution, Health Services fall events on watches — *and* where the operational tax lives (OEM fragmentation, per-brand behavior, cheap-device sensor variance). Apple risk is *platform permission*; Android risk is *platform entropy*. A safety company must price both. **Why incumbents underserve Android safety:** Google's Personal Safety app is Pixel-first (✅), Samsung's is Samsung-first (✅) — nobody owns *cross-OEM* family safety with medical seriousness; fragmentation, the thing that repels feature teams, is the moat for whoever builds the telemetry to tame it. **Ledger:** ✅ documented API behaviors, dontkillmyapp evidence, Health Services capabilities; 🟡 OEM killer specifics per firmware version (shift constantly — telemetry over documentation); 🔴 Google's internal fall-detection models. **Kill-relevant economics:** every OEM-specific workaround is permanent maintenance headcount — the B1 kill criterion (reposition Android if <95% protected-hours after a focused quarter) is what stops fragmentation from eating the company.

## 10. Design Review (highlights)

- **Google reviewer:** "Foreground service type `health` has policy prerequisites and Play review will read your justification. Your safety use is legitimate — write the declaration as carefully as an FDA claim."
- **Security researcher:** "Your DE-storage journal is readable at boot *without user credentials* — so is anything else on a stolen, rebooted phone. Prove the journal contains nothing an attacker wants." *(Design answer: IDs, states, timestamps only; contacts resolved from CE/cloud at send time — verify in threat model.)*
- **SRE:** "Your recovery path depends on `BOOT_COMPLETED`, which some OEMs delay by minutes. What covers the gap?" *(The cloud FSM's dead-man switch — it must not wait for the phone.)*
- **Investor:** "Two native apps, one team. Show me the shared-mental-model argument in the org chart, not just the slide."

## 11. Constraint Exercise

Design RAXHA's Android onboarding for a Samsung mid-range phone: you must obtain — in one flow the user actually completes — notification permission, exact-alarm capability, battery-optimization exemption, location permission (with background), and Health Connect grants; every screen adds drop-off risk. Order the asks, write the one-sentence justification for each, decide what protection level exists at each partial-consent state, and define the telemetry that tells you where the funnel leaks.

## 12. Chief Scientist's Verdict

**Confidence Ledger:** Kotlin coroutines/Flow as production-grade for sensing apps — ★★★★★. Direct Boot DE/CE split solving the locked-reboot case — ★★★★★ (documented platform mechanism, first-class API). "Foreground service + exemptions yields reliable 24/7 sensing across OEMs" — ★★★☆☆ (works on cooperative OEMs; documented failures on aggressive ones — hence telemetry, hence the kill criterion). "Health Services fall events are available and adequate on Wear OS" — ★★★☆☆ (✅ API exists on supported hardware; population coverage and event quality 🟡/🔴 — must be measured in shadow mode, not assumed).
**TRL:** Kotlin/Compose stack — 9. Direct Boot pattern — 9. Cross-OEM protected-hours ≥95% — **4–5 for RAXHA until proven** (this number is the whole Android bet; treat it as a hypothesis with a quarter-long experiment attached).
**Roadmap:** *MVP:* phone-side FSM + foreground-service armed modes + Health Services events where available. *V2:* per-OEM exemption playbooks, LTE-watch autonomy. *Research:* own on-watch models where Health Services granularity proves insufficient. *Never Build:* root/accessibility-service hacks for background persistence (Play death + trust death), OEM-specific forks of the risk engine (one core, adapters only).
**Competitor failures (sourced):** the entire documented genre of fitness/sleep apps failing on aggressive OEMs (dontkillmyapp's catalog ✅) — users blame the *app*, not the OEM; reviews say "missed my alarm," not "Xiaomi killed the service." RAXHA's degraded-protection honesty (B1) is the only defense against inheriting that blame.
**Kill Criteria:** inherits B1's 95% protected-hours criterion verbatim; adds — if the onboarding funnel (§11) completes below ~60% on top-3 OEMs after two iterations, the consumer Android motion is wrong: pivot Android to guided B2B deployment (care agencies configure devices) where onboarding is done by staff, not consumers.
**Historical Failures (Historian):** CyanogenMod/custom-ROM safety apps era — building below the platform's sanctioned surface never survives platform evolution. Early Wear OS (Android Wear 1.x–2.x) app ecosystem collapse — developers who bet on unstable platform primitives lost years; bet on the primitives Google itself depends on (Health Services powers Fitbit ✅ — that dependency is your stability signal).

---

*Competency 4 pairing: A-1.8 (PPG — the sensor that watches your blood) + B4 (HealthKit & Health Connect).*
