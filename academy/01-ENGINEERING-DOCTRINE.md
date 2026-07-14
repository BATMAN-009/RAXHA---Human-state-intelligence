# RAXHA Engineering Doctrine

> Standing decisions, adopted 2026-07-13. Every chapter, design, and line of code in this project is taught and judged against this document. Amend it deliberately; never violate it casually.
>
> **The prime constraint: 1 second can be the difference between life and death. Optimize for reliability, not convenience, not development speed, not cross-platform reach.**
>
> **Mission (adopted 2026-07-13; scope-hardened 2026-07-14).** **RAXHA is a Human State Intelligence System that detects meaningful changes in a person's physiological, behavioral, and contextual state and helps the right people respond at the right time. It does not diagnose diseases or provide treatment.** Every sensor, model, and line of code exists to answer one question: **"What is the current state of this human, how confident are we, and does someone need to know?"** Those three clauses map to the whole architecture — *state* (sensing + fusion + biomarkers), *confidence* (Decision #13), and *does someone need to know* (the escalation/response layer, RAXHA's actual moat). **RAXHA does not replace doctors, emergency responders, or caregivers — it helps ensure they are informed sooner when a person's state indicates they may need attention.** Any feature that doesn't serve the mission, or that crosses the Boundary (Decision #22), is out of scope.
>
> **Capstone framing (Competency-12 gate, 2026-07-13).** Seen whole, RAXHA is *a system for allocating human attention under uncertainty*: everything below the Decision Engine exists to answer "how likely is it this person needs help, and is that likelihood now high enough to justify interrupting another human being?" The Decision Engine is the top of the stack not because it is the smartest layer but because it is **the first layer that bears moral responsibility** — the point where evidence becomes the choice to disturb someone, mobilize resources, and spend trust. That is *why* it must be deterministic, calibrated, auditable, and explainable (Doctrine #3, #15, #18): it is where engineering becomes accountability.

---

## 1. The Ten Standing Decisions

1. **Native safety layer.** The sensing, detection, and escalation code is Swift (iOS/watchOS) and Kotlin (Android/Wear OS). No cross-platform framework touches the safety-critical path. Flutter/RN are permitted only for non-critical surfaces (e.g., a family-side dashboard), if ever.
2. **Risk engine on-device.** The SOS decision is made on the watch/phone. The cloud delivers and coordinates; it never *gates* an alert. If the network is down, the SOS still fires by every local means available (on-watch LTE, SMS, direct dial).
3. **No LLM in the detection path.** Emergency detection = deterministic logic + validated ML models, versioned and replayable. LLMs are restricted to: explaining alerts, summarizing history, assisting caregivers, answering questions.
4. **Tier autonomy invariant** (from B1): every tier — sensor hub, watch, phone, cloud — must do something useful when everything above it is unreachable.
5. **Data plane rule:** raw waveforms stay on-watch; features cross to phone; events cross to cloud. Battery, privacy, and bandwidth are solved by the same rule.
6. **Delivery contract:** at-least-once delivery + idempotent consumers, at every hop. An alert is not "sent" until a human acknowledged it; unacknowledged alerts climb the delivery ladder (push → SMS → voice).
7. **Latency is budgeted, not hoped for** (§3). Every pipeline stage has a measured target and a regression test.
8. **Shadow mode before live mode.** No detector alerts real users until it has run silently on fleet data and its real-world false-positive rate is known.
9. **Coverage telemetry is the first KPI.** The system continuously measures the % of each day the user was actually protected, and never hides a gap.
10. **Architecture before code.** Before production implementation: system design doc, data-flow diagrams, API contracts, threat model, failure-mode analysis (FMEA), latency budget, battery budget, and test plan. For a safety-critical system, architecture quality matters more than coding speed.
11. **No single device is ever the sole source of truth for life-critical state.** (Ratified from the Competency-2 gate, 2026-07-13: encrypted-at-rest storage is unreadable by an unattended reboot — on every platform, under some sequence of events, one device's disk fails you. Safety state is *distributed*: minimal journal on-device in boot-readable storage, mirror in the cloud with a dead-man's switch, and — where hardware allows — the watch as an independent escalator.)
12. **Three kinds of truth, never confused.** *Scientific truth* (physics, math, physiology — changes slowly; cite evidence). *Platform truth* (APIs, OS behavior — changes every release; re-verify against current documentation before implementation, whatever any chapter says). *Product truth* (countdown lengths, escalation policies, family graphs — our decisions, evidence-informed and revisable; never let a future engineer mistake them for laws of nature).
13. **Absence of evidence is never evidence of absence.** (Ratified from the Competency-4 gate, 2026-07-13.) The system must always represent two *separate* variables: confidence in the measurement, and confidence in the human state. "I know something is wrong" and "I no longer know what is happening" are different states demanding different responses — and they recur at every layer: a magnetometer unreliable without orientation being wrong; a PPG waveform gone without the heart stopping; a phone rebooted without the emergency ending; a cloud disconnect without the user being safe. **Corollary (asymmetric default):** when measurement confidence is low *and* context is alarming, resolve toward a low-cost human check ("are you OK?"), never toward silence — false alarms cost trust, false silence during an emergency is irreversible.
22. **The RAXHA Boundary — RAXHA is not a physician.** (Hard product boundary, adopted 2026-07-14.) RAXHA **detects** anomalies/emergencies, **monitors** changes from a person's own baseline, **assesses risk** using validated evidence, **notifies** trusted contacts when appropriate, **shares** relevant context for responders, **encourages** professional medical evaluation when warranted, and provides **decision support and safety monitoring**. RAXHA **does NOT** diagnose diseases, recommend or decide treatment, prescribe medication, provide medical advice, decide clinical management, act as a physician, or claim to cure/prevent/treat disease. When reframing content: *treating / managing disease / therapy / clinical recommendations / medical intervention by RAXHA* → *monitoring / risk estimation / early awareness / evidence-based escalation / supporting timely human response.* The medicine, physiology, clinical-validation, and regulatory chapters teach the **context RAXHA operates in** and how to build a reliable, evidence-based safety system — they do **not** teach RAXHA to practice medicine. This boundary is also a legal + ethical shield (Competency 15): the claim you can defend is a *detection/notification* claim, never a *diagnostic/therapeutic* one.
21. **Privacy is trust-minimization: eliminate single points of trust like single points of failure.** (Ratified from the Competency-13 gate, 2026-07-13 — the privacy twin of Decision #11.) Privacy is not the absence of data collection; it is the deliberate minimization of *how much trust the user must place in the system, the operator, the server, and every future business incentive.* Each architectural choice removes a trust dependency: on-device inference minimizes trust in the cloud; federated learning, in central training; secure aggregation, in the server; differential privacy, in future attackers; E2E encryption, in the infrastructure; data minimization, **in the company itself.** The strongest guarantee is not a policy promising good behavior but an architecture that stays safe even if every operator, server, and future incentive is assumed imperfect. **Corollary (federated fairness):** FL participation is self-selecting, so it silently underrepresents the elderly/rural/low-connectivity/low-end-device users RAXHA most needs to protect — publish per-round representation metrics and weight for *coverage equity*, not aggregate accuracy (the PPG skin-tone equity lesson, C4, at the learning layer).
20. **Missed emergencies are invisible; guard the threshold against silent drift.** (Ratified from the Competency-12 gate, 2026-07-13.) False alarms generate loud telemetry (complaints, cancellations); missed emergencies generate *none* (no dashboard shows the life not saved). This asymmetry creates constant organizational pressure to raise thresholds to cut false alarms — silently increasing false negatives with no counter-signal. Therefore: **decision thresholds are safety artifacts, governed exactly like models** — every change requires documented rationale, offline replay, retrospective evaluation, canary, (for medical scope) clinician review, and a rollback path. And *actively manufacture* the missing telemetry: synthetic fleet drills (B10), shadow-mode ground truth, false-negative surrogates, and FA/person-week *and* estimated-miss monitoring together — never optimize the visible metric alone.
19. **The optimization target is appropriate interruption, not detection accuracy.** (Ratified from the Competency-11 gate, 2026-07-13 — the objective function of the whole Decision Engine.) RAXHA never asks merely "is this abnormal?" It asks "is this abnormal *enough*, trustworthy *enough*, and important *enough* to justify interrupting another human being?" **Every alert spends trust; every unnecessary interruption depletes the family's willingness to respond to the next one.** So the system optimizes not for maximal detection but for *justified* interruption — spending the finite trust budget only when calibrated evidence (Decision #18), personal-baseline deviation (#16), context, sensor confidence, and consequence together warrant it. This unifies the base-rate trap (C1), alarm fatigue (medical), and the response-cost model into one objective: **maximize true help delivered per unit of trust spent.**
18. **Confidence must be *calibrated*, not merely reported.** (Ratified from the Competency-10 gate, 2026-07-13.) Decision #13 says represent uncertainty; this says *make it true*: a "70% confident" estimate must be right ~70% of the time. Fusion combines *calibrated beliefs* about the human state, not raw model scores — because the Kalman gain / Bayesian update is only as good as the uncertainties it's fed; an overconfident-but-wrong input produces a mathematically-optimal, operationally-lethal output. Every subsystem emitting a confidence must be calibrated and monitored: reliability diagrams, Expected Calibration Error, Brier score, post-hoc calibration (temperature scaling / isotonic), and continuous field recalibration against shadow-mode ground truth. Uncalibrated confidence is worse than none, because downstream layers *trust* it.
17. **Hierarchy of responsibility: no lower layer makes a higher layer's decision.** (Ratified from the Competency-9 gate, 2026-07-13.) The stack is sensors → signal processing → pattern recognition (TinyML) → context (HAR) → fusion → risk estimation → **policy (decides action)** → response. Each layer contributes *evidence with quantified uncertainty*; **only the Risk and Policy layers convert evidence into life-critical action.** A sensor never decides someone is safe; a classifier never decides whether family is called. **Sharpest enforceable corollary (the veto contract):** *context may raise or lower confidence, but may NEVER independently suppress a life-critical event.* "People don't fall while driving" is how this erodes — and car/motorcycle/cycling crashes are why it's lethal. Enforce the veto contract in code, architecture review, model validation, and safety tests; a context signal that can zero out a real emergency is a banned code path.
16. **Classify *changes* in people, not people.** (Ratified from the Competency-8 gate, 2026-07-13 — the unifying thesis of RAXHA's inference philosophy.) A person's absolute HR, HRV, gait speed, or movement pattern may differ enormously from another's and be perfectly healthy. The medically meaningful signal is almost always **departure from that individual's own stable baseline**, in context, with quantified uncertainty. Population models *initialize* (cold-start priors); personal models *govern*. This is the through-line from HRV (C5) → gait (C8) → HAR → anomaly detection (Module 9): the pipeline is sensors→state→**baseline→change→risk→intervention**, and "change from self" is where the intelligence lives. Corollary: this is also privacy-protective — modeling change-from-self needs no cross-person comparison and no identity database.
15. **Every output speaks the responder's vocabulary, never the sensor's.** (Ratified from the Competency-7 gate, 2026-07-13.) Accelerometer → "possible fall," not "2.8 g." PPG → "physiology unknown," not "no waveform." GPS → "likely at home," not raw lat/lon. Facility positioning → "Room 318, East Wing." Every layer's job is to transform measurement into information a family member, caregiver, or first responder can immediately act on — with its confidence attached. Corollary (expectation engineering): communicate what the system *cannot* know and why ("Room: unavailable — no indoor infrastructure"); users trust admitted uncertainty more than fabricated precision.
14. **Non-wear is the top field failure, and it is a product problem.** (From the Competency-4 gate.) No algorithm recovers physiology that was never measured. Monitor sensor-contact confidence over time as first-class coverage telemetry; detect chronic poor contact; coach the user/caregiver *before* an emergency. This is the documented failure that killed first-generation medical-alert pendants (stigma → non-wear → zero protection).

---

## 2. Production Architecture (approved reference)

```
 Apple Watch (native watchOS)            Wear OS watch (native Kotlin)
   CoreMotion · HealthKit                  Health Services · SensorManager
   WorkoutSession (when apt)               Bluetooth LE
        │  WatchConnectivity                    │  BLE / Data Layer API
        ▼                                       ▼
 iPhone (Swift)                          Android phone (Kotlin)
   ┌─────────────────────────┐             ┌─────────────────────────┐
   │  RISK ENGINE (on-device)│             │  RISK ENGINE (on-device)│
   │  signal processing      │             │  Health Connect · Room  │
   │  → sensor fusion        │             │  Foreground Svc (apt)   │
   │  → anomaly detection    │             │  WorkManager · Flow     │
   │  → risk scoring         │             └────────────┬────────────┘
   │  → SOS decision         │                          │
   └────────────┬────────────┘                          │
                └──────────────┬────────────────────────┘
                               ▼  realtime sync (events only)
                          BACKEND
        PostgreSQL · Supabase Auth · Supabase Realtime · Edge Functions
        Redis · Event Queue · Push Service · Object Storage
        (later: Kafka · Temporal · Kubernetes)
```

**Watch autonomy note (professor's amendment):** an LTE-capable watch must be able to complete the *entire* SOS path — decision and delivery — with the phone absent. The phone is the preferred Tier 2, not a required one.

---

## 3. Latency Budget

On-device pipeline (target: **< 500 ms** from sample to notification leaving the device):

| Stage | Target |
|-------|-------:|
| Sensor acquisition | < 50 ms |
| Filtering | < 20 ms |
| Feature extraction | < 30 ms |
| On-device inference | < 100 ms |
| Risk scoring | < 20 ms |
| SOS generation | < 50 ms |
| Push dispatch | < 300 ms (network-dependent) |

**Two clarifications that must never be forgotten:**

- **Deliberate latency ≠ pipeline latency.** For fall detection, a 30–60 s user-cancel countdown *dominates* end-to-end time — by design, as the false-positive/alarm-fatigue control. The <500 ms budget governs everything *around* that human window: detection before it, delivery after it. For unresponsive-user and crash paths the countdown shortens or vanishes, and the pipeline budget is the whole story.
- **The tail is the product.** Budget and monitor p99, not averages. A system that is instant 99% of the time and takes 30 s at 3 a.m. under Doze has failed its one job.

Every stage gets instrumentation and a CI regression gate.

---

## 4. Approved Technology Stack

**iOS:** Swift 6, SwiftUI, HealthKit, WatchConnectivity, CoreMotion, CoreLocation, Combine, async/await, BackgroundTasks, WidgetKit, ActivityKit (Live Activities — the natural surface for an active-incident UI).
*Constraint to respect:* HealthKit background delivery follows system scheduling and entitlement rules — it is not a guaranteed-instant channel; the safety path must not depend on it for immediacy.

**watchOS:** native app, SwiftUI, HealthKit, WorkoutSession (when appropriate), CoreMotion, WatchConnectivity, background tasks. The watch keeps monitoring when the phone is not active.

**Android:** Kotlin, Jetpack Compose, Health Connect, Health Services, Foreground Services (only where appropriate), WorkManager, Room, Coroutines, Flow.

**Wear OS:** Kotlin, Health Services, SensorManager, Bluetooth LE, Compose for Wear OS.

**Backend:** PostgreSQL (system of record), Supabase Auth + Realtime + Edge Functions (used as components, *not* as the entire backend), Redis, event queue, push notification service, object storage. Scale-out later: Kafka (event backbone), Temporal (escalation orchestration — a natural fit for the durable FSM), Kubernetes.

**AI layer — separated services, strict order:**
`Risk Engine → Signal Processing → Sensor Fusion → Anomaly Detection → Risk Scoring → SOS Decision`
Runtimes: TensorFlow Lite / Core ML / ONNX Runtime; TinyML on watch/hub. All models versioned, signed, canaried, shadow-tested.

---

## 5. Standing Role Contract (the "Master Prompt")

For all engineering teaching and implementation work, Claude acts as **Principal Software Architect and Technical Lead for RAXHA**, teaching to the level of independently designing, implementing, optimizing, testing, deploying, and scaling a system comparable to Apple Health, Google Personal Safety, Garmin Connect, and WHOOP.

Rules of the role:
- **Never generate code immediately. Teach first.**
- Every topic covers: why it exists → history → internal implementation → OS internals (iOS/Android/watchOS/Wear OS) → performance → latency implications → battery implications → security implications → failure modes → production architecture → real-world implementations (public documentation clearly distinguished from inference) → production-grade RAXHA build (diagrams, folder structure, API contracts, testing strategy, scalability plan).
- **Treat every feature as if a failure could delay an emergency alert.** Correctness, reliability, and fault tolerance over convenience and speed.

---

## 5b. Amendment 1 — Chapter Format v2: Founder Intelligence (adopted 2026-07-13)

Every chapter (and all retrofits of existing chapters) adds, after the Mastery Test:

**§18 Founder Intelligence** — answering:
1. Why hasn't Apple solved this perfectly? (the limitation no budget removes)
2–5. How WHOOP / Garmin / Google / Samsung each approach it differently — sampling, battery, algorithms, *business model* — and why those differences are strategy, not accident.
6. Why doesn't everyone do this? (technical / battery / medical / legal / privacy / economic barriers)
7. Startup opportunities adjacent to this technology.
8. RAXHA strategy (not engineering): the actual decisions, with battery/false-alarm/privacy/cost trade-offs stated.
9. Research that doesn't exist yet — "if I were doing a PhD, what would I publish?" (each = a potential moat)
10. **Patent landscape** — themes and named families, under the Patent Rigor Rule below.
11. **Reverse-engineering ledger:** every claim about a company tagged ✅ publicly documented / 🟡 strong inference / 🔴 unknown. Never build a RAXHA assumption on a 🟡 without saying so.

**§19 Design Review** — the chapter's design defended before a hostile panel (Apple Health, Google Health, WHOOP, Garmin, FDA reviewer, physician, investor, security researcher, privacy advocate), each attacking from their own incentives.

**§20 Constraint Exercise** — a decision-making problem in the Apple-interview style: hard resource constraints (RAM, µA, BOM, battery-days, false-alarm ceiling) → design the product, defend the trade-offs.

**Competency framing:** progression is measured in *competencies*, not weeks. Each competency states learning objectives, engineering objectives, founder objectives, research objectives, and completion criteria. "Competency unlocked," never "week unlocked."

**Patent Rigor Rule:** patent *numbers* are cited only when verifiable (live search or certain public reporting); otherwise the chapter names the patent *family/theme*, the assignee, and the exact Google Patents query to find it. A fabricated patent number is worse than none — this Bible must never contain one.

---

## 5c. Amendment 2 — The Chief Scientist's Verdict (adopted 2026-07-13)

Every chapter ends with **§21 Chief Scientist's Verdict**, one consolidated section with five subsections:

1. **Scientific Confidence Ledger** — the chapter's load-bearing claims, each rated:
   ★★★★★ replicated studies + commercial deployment + clinical evidence · ★★★★ strong literature, deployed somewhere · ★★★ promising, multiple studies, not production-proven · ★★ research-only, limited/conflicting evidence · ★ exploratory, single-study or speculative.
2. **TRL table** — NASA 1–9 scale, assigned only to *precisely scoped capabilities* (e.g., "wrist detection of tonic-clonic seizures," never "seizure detection"). TRL = implementation maturity; it must be read WITH the Confidence Ledger — high TRL with low evidence stars (e.g., cuffless BP products) is a warning, not a green light.
3. **Roadmap Placement** — MVP / V2 / V3 / Research Lab / **Never Build (with reason)**. This subsection is the feature-creep firewall.
4. **Competitor Failure Analysis** — documented failures only (sourced complaints, press, regulatory actions, teardowns; unsourced speculation gets 🟡 or stays out). Learning from failures outranks copying successes.
5. **Kill Criteria** — pre-registered falsification: what measured evidence (false-alarm rate, battery cost, regulatory burden, privacy trade-off, sensitivity floor) would prove the feature non-viable, decided *before* attachment forms.

**Standing kill criterion for the whole company** (from Life360's documented location-data-broker scandal): RAXHA never monetizes location or sensor data. The day that changes is the day the product's reason to exist ends.

**Structural freeze:** with Amendments 1–2, the chapter template (§1–21) and curriculum structure are FROZEN. Further structural proposals are queued in writing and reviewed only after the currently open competency gate is passed — a knowledge system that is perpetually re-architected is a knowledge system nobody is learning from.

---

## 6. Pre-Code Architecture Document Set

To be produced (several weeks of work, before production code):

1. System design document (tiers, components, trust boundaries)
2. Data-flow diagrams (data plane + control plane)
3. API contracts (watch↔phone, phone↔cloud, cloud↔responder)
4. Threat model (STRIDE across every link; sensor-level attacks from A-track §11s)
5. Failure-mode analysis (FMEA table: failure → effect → detection → mitigation)
6. Latency budget (§3, expanded per-path: fall / crash / cardiac / manual SOS)
7. Battery budget (per-tier mAh/day allocation and measurement plan)
8. Testing plan (replay CI, chaos drills, shadow mode, field drill protocol)
