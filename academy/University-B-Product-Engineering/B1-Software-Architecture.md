# Chapter B1 — Software Architecture for Sensing Platforms

> **Paired with:** A-1.1 (Accelerometer). That chapter ended with the cascade pattern — sensor interrupt → TinyML → context fusion → human confirmation → alert. This chapter is about the software system that makes that cascade *real*: what runs where, how data and decisions move, why the OS will fight you, and what "Apple-level" actually means in architectural terms.

---

## 1. Definition & the problem being solved

A **sensing platform architecture** is the end-to-end structure of a system that continuously observes the physical world through sensors, makes decisions on that stream, and takes real-world actions — under hard constraints of battery, privacy, unreliable networks, and operating systems that actively suppress background work.

RAXHA is a specific, hard instance: a **safety-critical, always-on, distributed, real-time event-detection system** spanning four computers (sensor hub → watch → phone → cloud), where the cost of a missed event is potentially a life and the cost of too many false events is the user disabling you (A-1.1 §12, alarm fatigue).

The architecture question is never "what framework?" It is: **for each piece of computation, which of the four computers runs it, and what happens when each link between them is broken?**

---

## 2. The reference architecture: four tiers, two planes

```
┌─────────────────────────────────────────────────────────────────┐
│  TIER 0 — SENSOR HUB (inside/beside the sensor, µA, always-on)  │
│  hardware interrupts: free-fall, high-g, wake-on-motion, FIFO   │
├─────────────────────────────────────────────────────────────────┤
│  TIER 1 — WATCH (MCU/SoC, mAh budget, mostly asleep)            │
│  rolling raw buffer · TinyML confirmer · local alarm UI         │
├─────────────────────────────────────────────────────────────────┤
│  TIER 2 — PHONE (real OS, real battery, usually reachable)      │
│  context fusion (location, activity, time) · escalation state   │
│  machine · countdown UI · contact management                    │
├─────────────────────────────────────────────────────────────────┤
│  TIER 3 — CLOUD (always up, never trusted with raw data)        │
│  alert fan-out · push/SMS/voice delivery · live-location relay  │
│  · acknowledgment tracking · audit log                          │
└─────────────────────────────────────────────────────────────────┘
```

Two planes cross these tiers:

- **Data plane:** sensor samples flow *up only as far as they must*. Raw waveforms live and die on the watch; features cross to the phone; *events* cross to the cloud. This single rule simultaneously solves battery (radio is the most expensive thing you do), privacy (raw motion is a biometric — A-1.1 §11), and bandwidth.
- **Control plane:** configuration, model updates, and escalation policies flow *down*. Versioned, signed, staged-rollout — because pushing a bad model to a safety device is a recall-class event.

**The invariant that defines the whole design:** *every tier must be able to do something useful when everything above it is unreachable.* Watch with no phone in range → local alarm sound + on-watch SOS via LTE if the watch has it. Phone with no network → SMS fallback, retry queue. Cloud unreachable → phone dials contacts directly via the telephony stack. A safety product's architecture is judged entirely by its behavior in these degraded states; the happy path is trivial.

---

## 3. The OS as adversary: what platforms forbid, and the sanctioned paths

This is the section that separates people who have read the API docs from people who have shipped. Both major platforms are engineered to *kill* exactly the thing RAXHA wants to do (continuous background sensing), because 99% of apps that want it are battery abusers.

### iOS / watchOS (the strictest)
- Third-party apps get **no truly continuous high-rate background sensor access** on watchOS. Workout sessions (`HKWorkoutSession`) keep you running but are semantically "exercise," not 24/7.
- **The sanctioned paths:** consume Apple's own detectors (`CMFallDetectionManager` with entitlement, significant-location, `CMSensorRecorder`'s retrospective 50 Hz buffer), background app refresh, silent push wakeups, and `BGProcessingTask` for batch work.
- **Architectural consequence:** on Apple hardware, RAXHA's Tier 0/1 *is Apple's* — you own Tier 2/3 (context fusion and the response layer). Fighting this is how startups die; designing for it is how you ship in weeks.

### Android / Wear OS (permissive but treacherous)
- You *can* run a foreground service with a persistent notification and sample sensors continuously — the OS allows it.
- But **Doze, App Standby buckets, and OEM battery managers** (aggressive on several major brands) will throttle, defer, or kill you anyway. This is the root cause of the "nightly 3-hour data gaps" failure in A-1.1 §14.
- **The sanctioned paths:** sensor batching (`maxReportLatencyUs` — hub FIFO holds data while the AP sleeps), wake-up sensor variants, Health Services on Wear OS (detection offloaded to the low-power core), high-priority FCM pushes to wake the app, and asking the user for battery-optimization exemption (allowed for safety apps, but OEMs differ).
- **Architectural consequence:** on Android you own more of the stack and more of the risk. You must build **gap telemetry** — the system continuously measures its own blind spots and tells the user "protection was degraded last night," because silently failing coverage is worse than no product.

> **Design doctrine:** treat "the OS killed us" as a *normal state*, not an exception. The architecture carries a heartbeat (watch→phone→cloud "I'm alive and sensing" pings); a missing heartbeat is itself a signal — degraded-protection warnings, never silence.

### 3b. The vendors' own architectures (labeled, per University rules)
- **Apple [V+I]:** fall/crash detection runs in the OS/firmware layer on dedicated low-power coprocessors (Apple documents the always-on processor and sensor additions; exact partitioning is inferred). Detection is a *platform feature*; apps subscribe to events. Everything on-device; the cloud's role is SOS routing.
- **Google [V]:** Wear OS Health Services explicitly moves detection onto the MCU and delivers events, mirroring the Tier-0/1-owned-by-platform model. Pixel's fall detection similarly platform-level.
- **Garmin [V]:** incident detection is scoped to GPS activities — an architectural choice to only run detection when context priors are favorable (fewer false positives, bounded battery cost).

The common shape: **the closer to the sensor, the lower in the stack, the more privileged the code.** RAXHA can't be in firmware, so RAXHA's edge is at the layers above: multi-signal fusion, the family-response experience, and cross-device coverage — the layers platforms leave open.

---

## 4. Event-driven core: the escalation state machine

The heart of Tier 2 is not a neural network — it's a **finite state machine**, explicitly modeled, persisted, and replayable:

```
IDLE ──trigger──▶ SUSPECTED ──confirm──▶ COUNTDOWN ──timeout──▶ ALERTING
  ▲                  │ reject                │ user cancel          │
  └──────────────────┴───────────────────────┘                      ▼
                                              ACKNOWLEDGED ◀─ contact ack
       ESCALATING (next contact / emergency services) ◀── ack timeout
```

Rules that make it safety-grade:

1. **Every transition is durably logged before it takes effect** (write-ahead). If the app crashes mid-COUNTDOWN, restart resumes the countdown — it does not silently return to IDLE.
2. **Timers survive process death** (alarms/scheduled jobs, not in-memory timers).
3. **Idempotent transitions:** trigger events carry IDs; a redelivered event cannot start a second parallel escalation.
4. **The cancel path is as engineered as the alert path.** A user fumbling to cancel while embarrassed is the most common real-world interaction (Apple's countdown UX — big cancel, haptics, escalating alarm sound — is the studied benchmark).
5. **Policy is data, not code:** countdown length, contact ordering, quiet hours are configuration on the control plane — changeable without an app release.

This FSM is also your **test harness**: because transitions are explicit and logged, you can replay recorded sensor streams through the whole pipeline in CI and assert "this trace must end in ALERTING within 90 s" — the replay-based CI promised in A-1.1 §13.

---

## 5. Data plane engineering

- **On-watch ring buffer:** a fixed-size circular buffer of raw samples (e.g., 20 s at 100 Hz ≈ 12 KB) so that when a trigger fires you already possess the *pre-event* window — you cannot go back in time to sample it. This tiny structure is why Tier 0's cheap thresholds are acceptable: they only need to be *sensitive*, never *specific*, because Tier 1 re-examines the full buffered context.
- **Watch↔phone link (deep dive in B7):** BLE gives you ~KB/s comfortably; design messages as compact event/feature records, never streams. Assume the link is down ~10% of the time (phone left in another room); queue with store-and-forward.
- **Phone↔cloud:** an outbox pattern — events written to a local durable queue, uploaded with retry/backoff, acknowledged, then pruned. **At-least-once delivery + idempotent server** is the only sane contract; exactly-once is a lie and at-most-once loses alerts.
- **Storage policy = privacy policy:** raw windows retained on-device only, short TTL, opt-in contribution for model improvement (the shadow-mode fleet data of A-1.1 §13); cloud stores events, decisions, delivery receipts. Design the schema so a subpoena or a breach at the cloud tier exposes *no waveform biometrics*.

---

## 6. Backend (preview — full treatment in B10)

The cloud tier is deliberately boring, and boring is the achievement:

- **Ingest:** authenticated event endpoint → durable queue → escalation orchestrator (the server-side mirror of the FSM, handling multi-contact fan-out).
- **Delivery ladder:** push notification → SMS → automated voice call (telephony API), each rung with delivery-receipt tracking and timeout-based fallthrough. An alert is not "sent" until a human acknowledged it; unacknowledged alerts climb the ladder.
- **Live location relay:** short-lived, token-scoped location-sharing channel for responders — expires after the incident closes.
- **SLOs:** trigger-to-first-notification p99 latency (seconds), delivery success rate, and end-to-end drill success (synthetic test falls injected fleet-wide daily — the safety-system equivalent of a fire drill).

---

## 7. Observability: the fleet is the instrument

You cannot debug a safety fleet from bug reports. Built-in from day one:

- **Coverage telemetry:** % of each day each user was actually protected (sensors sampling, pipeline alive, link up). This is the product's real KPI before any fall ever happens.
- **Shadow mode:** new models run alongside production, logging would-have-fired decisions without alerting — the only ethical way to measure real-world false-positive rates before enabling a model (closes the SisFall→FARSEEING gap from A-1.1 §14 with your own fleet's ground truth).
- **Every alert becomes a labeled sample:** user canceled → probable false positive; contact confirmed → true positive. The product's operation *is* the data engine. (Federated/private learning on this: Module 13 / B11.)

---

## 8. Failure analysis — architecture edition

| Failure | Root cause | Architectural defense |
|---|---|---|
| Alert never sent; app was dead | In-memory state, no durable FSM | Write-ahead state, persistent timers, resume-on-restart |
| Duplicate alerts terrify family | Retries without idempotency | Event IDs, dedup at every tier |
| Silent coverage gaps | OEM killed the service; nobody noticed | Heartbeats + gap telemetry + degraded-protection UX |
| Alert sent, nobody saw it | Push treated as fire-and-forget | Delivery ladder with acks and fallthrough |
| Bad model update fleet-wide | Unstaged control-plane push | Signed, versioned, canaried rollouts; shadow mode first |
| Works in demo, dies at 3 a.m. | Tested only the happy path | Replay CI + chaos drills (kill link/process mid-escalation) |

---

## 9. RAXHA application — the distilled doctrine

- **MVP shape:** Apple path = consume `CMFallDetectionManager` + own the Tier 2/3 response layer. Android path = Health Services + foreground service + gap telemetry. One shared cloud with the delivery ladder. This is buildable by a small team in months *because* it respects platform boundaries.
- **The moat is not detection.** Apple owns detection on Apple hardware forever. RAXHA's ownable layers: multi-device context fusion, the family-side experience (acknowledgment, live location, escalation), cross-platform coverage, and — later — personalized models from fleet shadow data.
- **Do NOT:** stream raw sensor data to the cloud (battery, privacy, and it doesn't even help); build cross-platform-first; treat the FSM as implicit code paths; ship any detector that hasn't run in shadow mode.

---

## 10. Mastery Test — B1

1. State the four-tier model and, for each tier, name what it computes and what it must still accomplish when the tier above is unreachable.
2. Why does the rule "raw data stays on-watch, features cross to phone, events cross to cloud" simultaneously serve battery, privacy, and bandwidth? Which of the three would break first if you streamed raw data up, and why?
3. Your escalation FSM is in COUNTDOWN and the phone reboots. Walk through exactly what your architecture does, and name the two mechanisms that make it possible.
4. Explain why "at-least-once delivery + idempotent consumers" is the correct contract for alerts, and what concretely goes wrong under at-most-once and under naive retries without idempotency.
5. Compare how RAXHA's Tier-0/1 differs on iOS vs Android, and how that asymmetry should change what the company invests in on each platform.
6. Design the "coverage telemetry" metric precisely: what signals feed it, how you'd detect an OEM-killed service within an hour, and what the user should see.
7. What is shadow mode, and why is it the *only* ethical bridge across the lab-to-life gap identified in A-1.1 §12/§14?
8. A PM proposes React Native to ship both platforms faster. Give the strongest technical argument for and against, and your ruling for RAXHA specifically.

---

---

## 11. Founder Intelligence

**Why do the platforms leave the response layer open?** Apple/Google absorbed *detection* (it's on-device, liability-light, sells hardware) but not the *response network*: multi-family coordination, caregiver workflows, acknowledgment loops, cross-platform coverage, elder-care B2B. 🟡 Inference: the response layer is operationally heavy (support, internationalized emergency plumbing, per-country telephony) and doesn't sell devices — structurally unattractive to hardware companies, structurally perfect for a focused startup. ✅ Life360 proved the model: family-safety network, freemium subscription, massive scale — without owning any sensor. **RAXHA's position: Life360's business shape + medically serious detection depth.**

**Why doesn't everyone build safety backends?** An alerting business is an SLA business: 24/7 on-call, delivery-ladder telephony costs, per-country emergency-services law, and one bad outage = existential press. The moat is operational excellence, which cannot be copied by a feature team in a quarter.

**Research that doesn't exist:** formal verification of escalation state machines (model-checking the FSM against "alert can never be lost" invariants — publishable and directly productizable); optimal escalation policies as decision theory (who to alert, when, at what confidence).

**Reverse-engineering ledger:** Apple SOS pipeline — ✅ countdown UX, satellite SOS existence, on-device detection; 🟡 server-side escalation shape; 🔴 delivery SLOs, retry ladders. Never assume Apple's cloud does something clever you can't see — design to your own invariants.

## 12. Design Review (panel highlights)

- **Investor:** "Detection is commoditized by the OS — agreed. But Life360 has the family graph already. Why doesn't Life360 add your detection layer before you add their graph?" *(The honest competitive question. Answer: depth of the medical/detection stack + watch-native engineering is a different company's DNA — but move fast.)*
- **SRE reviewer:** "Your delivery ladder's voice-call rung depends on one telephony vendor. Multi-vendor failover or it's not a safety system."
- **Privacy advocate:** "Your cloud stores 'events, decisions, delivery receipts.' An event with location + timestamp + 'fall' *is* health data. GDPR/HIPAA posture, retention TTLs — in writing."
- **FDA reviewer:** "The moment your marketing says 'detects cardiac events,' your architecture document set (§6 of doctrine) becomes a regulatory submission. Keep the claims ledger versioned with the code."

## 13. Constraint Exercise

Design RAXHA's MVP backend with: **2 engineers, $500/month infra, 10,000 users, p99 trigger-to-first-push < 5 s, and zero tolerance for lost alerts.** What do you build vs buy (queue? telephony? push?), what single-points-of-failure do you consciously accept, and what's the one metric on the wall?

---

## 14. Chief Scientist's Verdict

**Confidence Ledger:** Durable FSM + write-ahead + idempotency as the correct reliability pattern — ★★★★★ (decades of distributed-systems evidence; it's how payment systems work, and an alert is a payment with higher stakes). At-least-once + idempotent consumers as the only sane delivery contract — ★★★★★. "OEM battery killers cause real coverage gaps on Android" — ★★★★☆ (extensively documented by developers; per-OEM specifics shift with releases 🟡). "Shadow mode measures true field false-alarm rates" — ★★★★☆ (sound methodology; requires honest ground-truth labeling to earn the fifth star).

**TRL:** Every architectural component here (event sourcing, outbox, delivery ladders, FSM orchestration) — 9; these are boring, proven patterns, which is precisely why they're chosen. The novel *composition* (four-tier safety cascade with coverage telemetry on consumer wearables) — 6–7: practiced piecewise by incumbents, unproven as an integrated startup product.

**Roadmap Placement:** *MVP:* durable FSM, outbox, push→SMS ladder, coverage telemetry. *V2:* voice-call rung, multi-vendor telephony failover, Temporal-backed orchestration. *V3:* federated model updates. *Never Build:* raw-waveform cloud storage (doctrine §1.5 — battery, privacy, and it buys nothing); cloud-gated SOS decisions (doctrine §1.2).

**Competitor Failure Analysis (sourced):** Life360 — the location-data-broker scandal (documented) is the canonical response-layer failure: the business model attacked its own trust asset. Medical alert services — documented complaints center on false alarms and monthly-fee fatigue, not detection quality: the *response experience* is where incumbents bleed. Apple — crash-detection false-911-call waves (documented, ski slopes/roller coasters 2022–23) burdened real dispatch centers: even the best-resourced player shipped a context-gating failure; humility and shadow mode are cheaper than headlines.

**Kill Criteria:** If Android coverage telemetry can't reach ~95% protected-hours on the top-5 OEMs after a focused quarter → reposition Android as phone-context-plus-manual-SOS and lead with iOS/watch. If p99 trigger-to-first-push exceeds 5 s under load tests → no user growth until fixed (growth on a broken promise is negative growth). If a proposed feature requires monetizing location/sensor data to pencil out → the feature dies, per standing doctrine.

**Historical Failures (Historian's ledger):**
- **Pebble** (†2016) — beloved product, correct architecture instincts, killed by unit economics against giants with infinite subsidy. Axis: business. Lesson: RAXHA must not compete on *hardware* at all — ride the watches the giants subsidize.
- **Scanadu Scout** — crowdfunded medical scanner shipped as a "research study," then bricked when the study ended; user fury, FTC complaints. Axis: regulation + trust. Lesson: never ship a safety promise whose regulatory foundation has an expiry date.
- **AliveCor** (the survivor counter-example) — went *through* FDA clearance early, narrow claim (ECG/AFib), and outlived far better-funded rivals. Lesson: in medical-adjacent products, regulatory rigor is a moat, not a tax — RAXHA's Module 16 exists because of companies like this.

---

*Paired next competency: A-1.2 (Gyroscope) + B2 (Swift & the Apple development stack).*
