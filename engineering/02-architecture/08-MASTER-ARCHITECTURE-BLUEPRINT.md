# 08 — Master Architecture Blueprint

> **RAXHA is not a collection of sensors, apps, or AI models. It is a deterministic Human State Intelligence Platform whose purpose is to transform uncertain evidence into the most appropriate human response while preserving trust, privacy, and safety.**

> **Scope of this document:** it answers **only** *"how is the system composed?"* — subsystems, their relationships, and data flow. It does not restate *why* (North Star), *who* (PRD), *why-chosen* (ADR/PDR), *APIs* (12), or *requirements* (09). Foundation is **locked** (00A); a discovered conflict → STOP → RFC, never a silent edit. Every subsystem cites its `Derived From:`; a block that cannot is not permitted to exist. Vocabulary is the frozen set (08B Part A). **Part A** is technology-free and must survive any tech swap; **Part B** binds technology.

---

# PART A — CONCEPTUAL ARCHITECTURE (technology-free)

## A1. Context Diagram
```
        ┌──────────────────────── RAXHA (system) ────────────────────────┐
 Wearer │  senses the wearer's state, decides if help is warranted,      │  Family /
 ──────▶│  and coordinates a response                                    │──▶ Chosen
        └───────────────────────────────────────────────────────────────┘  Responders
              ▲ platform signals (as evidence)        │ shares context
              │                                        ▼
        Platform detectors (Apple, …)           Real-world Emergency (ground truth)
```
RAXHA sits between one wearer and their chosen responders. It consumes the wearer's signals and platform detections **as evidence**, and its only outward action is to **inform the right humans**. It never acts *on* the wearer (no treatment — D22).

## A2. Composition (the spine)
```
      Human ──▶ Sensing Layer ──▶ Human State Engine ──▶ Risk Engine ──▶ Policy Engine ──▶ Response & Escalation ──▶ Responders
                     │                    │                  │               │                     │
                     └──────────── Coverage Monitor ─────────┘               │            Delivery & Coordination
                                                                             │                     │
                     (cross-cutting: Privacy/Trust Plane · Model & Threshold Governance)
```
Evidence flows **up** one rung at a time (Signal → Observation → Evidence → Human State → Risk → Policy Decision → Incident → Alert). Only the Policy Engine converts evidence into action (D17). Two planes cut across every subsystem: the **Privacy/Trust Plane** (D21) and **Model & Threshold Governance** (D08/D20).

## A3. Subsystems

### Sensing Layer
- **Purpose:** acquire the wearer's Signals, turn them into quality-tagged Observations and validated Evidence (including platform detections admitted as evidence).
- **Inputs:** raw sensor Signals; platform detections; on-body/Coverage status.
- **Outputs:** Evidence (with calibrated Confidence and timestamps).
- **Failure Behaviour:** on sensor loss or low quality, emits *"unknown"* Evidence with low Confidence — never fabricates a value, never goes silent (D13).
- **Evidence Produced:** per-signal quality/SQI, on-body state, acquisition gaps.
- *Derived From:* ADR-001, ADR-004, ADR-011, ADR-013 · D01, D04, D05 · PRD §4.

### Human State Engine
- **Purpose:** fuse Evidence + personal Baseline into the single canonical Human State with calibrated Confidence.
- **Inputs:** Evidence from the Sensing Layer; the wearer's Baseline.
- **Outputs:** one Human State estimate (+ Confidence) at time *t*.
- **Failure Behaviour:** contradictory Evidence is resolved into a reconciling state (never averaged away); missing modalities widen uncertainty rather than defaulting to "normal" (D13/D18).
- **Evidence Produced:** the fused state, its Confidence, and which Evidence drove it.
- *Derived From:* ADR-006, ADR-012 · D13, D16, D18 · North Star.

### Risk Engine
- **Purpose:** convert Human State + Candidates + context into a calibrated Risk assessment — RAXHA's own independent judgment (platform detections are inputs, never verdicts).
- **Inputs:** Human State (+ Confidence); Candidates; context (activity, place, time, Coverage).
- **Outputs:** a Risk assessment (calibrated probability + severity + contributing Evidence).
- **Failure Behaviour:** degrades gracefully as inputs drop, widening uncertainty; a single faulty input cannot dominate; never inflates Risk on uncalibrated Confidence (D18).
- **Evidence Produced:** the Risk value, its Confidence, and its rationale.
- *Derived From:* ADR-002, ADR-004 · D02, D16, D18, D19 · PRD §1, §3 · PDR-008.

### Policy Engine
- **Purpose:** the only layer that turns Risk into action — selecting `{none · observe · check-in · countdown · alert · escalate}` under an explicit, personalized, trust-aware cost model, explainably.
- **Inputs:** Risk assessment; context; personalization; recent-alarm/trust state.
- **Outputs:** a Policy Decision with a human-readable rationale (D15).
- **Failure Behaviour:** deterministic and replayable (D03); context may lower/raise Risk but can **never** veto a life-critical event (D17); low Confidence + alarming context resolves toward a low-cost human check, never silence (D13).
- **Evidence Produced:** the decision, its rationale, and the trust cost spent.
- *Derived From:* ADR-008, ADR-009, ADR-014 · D03, D15, D17, D19 · PRD §4, §15.

### Response & Escalation Engine
- **Purpose:** carry a Policy Decision through the Incident lifecycle — open Incident, run the countdown, climb the delivery ladder to Alerts, track acknowledgment, resolve.
- **Inputs:** a Policy Decision; contact/escalation configuration; acknowledgments.
- **Outputs:** an Incident with EscalationState; Alerts to responders.
- **Failure Behaviour:** state is durable and reboot-recoverable (D11); idempotent (no duplicate Alerts); an Alert is not "done" until a human acknowledges (D06); survives loss of any single device (dead-man's switch).
- **Evidence Produced:** the Incident timeline, delivery receipts, acknowledgments (audit).
- *Derived From:* ADR-007, ADR-010 · D06, D11 · PRD §4 · PDR-003.

### Coverage Monitor
- **Purpose:** continuously measure whether protection is actually active, and coach before an emergency.
- **Inputs:** on-body state, battery, link reachability, pipeline liveness.
- **Outputs:** the Coverage state (Protected / Degraded / Alerting) and coaching nudges.
- **Failure Behaviour:** a coverage gap is surfaced, never hidden (D09); chronic non-wear triggers proactive coaching (D14).
- **Evidence Produced:** % protected over time; gap events; non-wear signals.
- *Derived From:* D09, D14 · PRD §4 · PDR-007.

### Delivery & Coordination (cloud)
- **Purpose:** coordinate multi-contact delivery and hold the independent Incident mirror — coordination only, never inference or gating.
- **Inputs:** Incident events (idempotent); acknowledgments; contact graph.
- **Outputs:** delivered Alerts across the ladder; escalation; the dead-man's switch firing.
- **Failure Behaviour:** persists before processing; at-least-once + idempotent; multi-path delivery; **never gates the SOS decision** (D02); escalates on a vanished mid-Incident heartbeat (D11).
- **Evidence Produced:** delivery SLO metrics, acknowledgment records, drill results.
- *Derived From:* ADR-005, ADR-007 · D02, D06, D11 · PDR-003.

### Cross-cutting planes
- **Privacy/Trust Plane** — raw stays on the wearer's device; features cross to phone; only events cross to cloud; sharing is incident-only and expiring; nothing sellable is stored. *Derived From:* ADR-013 · D05, D21 · PRD §10.
- **Model & Threshold Governance** — models *and* thresholds ship only via signed, shadow-tested, canaried, rollback-able change, with two-sided (false-alarm + estimated-miss) monitoring. *Derived From:* ADR-015 · D08, D20.

## A4. Data Flow (with the data-plane rule)
```
 WEARER DEVICE            PHONE                     CLOUD
 raw Signals ─┐           │                         │
 Observations ┤ (die here)│                         │
 Evidence ────┴──────────▶ Human State → Risk →      │
                           Policy → Incident ──event▶ Delivery & Coordination ──▶ Responders
 (raw never leaves)        (features cross)          (events only; no raw/waveform)
```
The rung that crosses each boundary is fixed by D05: **raw dies on the wearer's device, features cross to the phone, only events cross to the cloud.**

## A5. Sequence (per path — conceptual)
```
FALL:      Evidence(free-fall→impact) → Human State(down/impact) → Risk(elevated) →
           Policy(COUNTDOWN) → [wearer may cancel] → Incident → Alerts → Ack
CRASH:     Evidence(high-g + context) → Human State → Risk(high, short/no countdown) → Incident → Alerts
CARDIAC:   Evidence(physiology vs Baseline, corroborated) → Human State → Risk → Policy(check-in→escalate) → Incident
MANUAL SOS: wearer action → Policy(immediate) → Incident → Alerts
```
All four converge on the same **Incident → Alert → Acknowledgment** spine; they differ only in how Risk and countdown are set.

## A6. State Machine (the Incident)
```
IDLE → SUSPECTED → COUNTDOWN → ALERTING → ACKNOWLEDGED
   ▲       │(reject)     │(cancel)     │             │
   └───────┴─────────────┘             └─▶ ESCALATING ┴─▶ RESOLVED
   (every transition durable, idempotent, reboot-recoverable — D11)
```

## A7. Trust Boundary
```
[ wearer's body ]→( device: high trust, raw data )→( phone: features )→‖ TRUST EDGE ‖→( cloud: events only, zero raw )→( responders: incident-scoped, expiring )
```
Trust *decreases* outward; the amount of data crossing each edge decreases with it (D21). The cloud is treated as untrusted-with-raw-data by construction.

## A8. Failure Propagation (containment, not cascade)
```
 Sensor fails    → "unknown" Evidence (contained at Sensing; state widens uncertainty)
 Phone dies      → watch continues; cloud dead-man's switch escalates (D11)
 Network down    → local decision + SMS/voice fallback; queue & retry (D02)
 Cloud down      → device decides & delivers by local means (D02)
 Bad model/thresh→ shadow/canary/rollback stops it pre-fleet (D08/D20)
```
No single failure reaches the wearer as silent non-protection; each is contained at its tier or backstopped by the next (D04/D11).

## A9. Latency (conceptual budget)
```
 Detection→decision pipeline: < 500 ms (D07)   |  Deliberate cancel countdown: 30–60 s (fall; shorter/none for crash/unresponsive)
 Decision→first responder notification: seconds (p99, not average)
```
The pipeline budget governs everything *around* the human cancel window; the countdown is a *deliberate* latency (the false-alarm control), not pipeline slowness.

---

# PART B — IMPLEMENTATION ARCHITECTURE (technology-bound)

> Part B binds Part A to technology. **If anything here changes, Part A must not** — that is the test of whether Part A is truly architecture.

## B1. Container Diagram (v1 = Apple-first, per PDR-002)
```
 Apple Watch app (native, watchOS)  ── WatchConnectivity ──  iPhone app (native, Swift/SwiftUI)
   Sensing adapters · local FSM                              RaxhaCore (pure): Human State/Risk/Policy/FSM
                                                             · on-device inference · durable journal
                                                                     │  events only (outbox)
                                                                     ▼
                        Backend: ingest · durable queue · escalation orchestrator (FSM mirror /
                        dead-man's switch) · delivery ladder (push/SMS/voice) · audit · relational store
                                                                     │
                                                             Responders' devices
```

## B2. Deployment (v1)
```
 [Apple Watch] ⇄ [iPhone] ⇄ [Cloud region: API · queue · orchestrator · DB · object store]
                                          └─ telephony/push vendors (multi-vendor delivery)
```

## B3. Technology binding (Part A subsystem → v1 tech)
| Part A subsystem | v1 implementation | Portable to |
|---|---|---|
| Sensing Layer | CoreMotion / HealthKit adapters; platform fall event as evidence | Health Services / SensorManager (Wear OS) |
| Human State / Risk / Policy | `RaxhaCore` — pure, hexagonal (ADR-011); Core ML on-device | Kotlin core; LiteRT |
| Response & Escalation | on-device durable FSM (SQLite journal) + backend orchestrator | any durable store / workflow engine |
| Delivery & Coordination | relational DB + queue + push/SMS/voice vendors | any equivalent cloud stack |
| Coverage / Privacy / Governance | on-device telemetry; E2E + minimization; signed model registry | platform-agnostic |
*(These are PDR/tech choices — swapping any cell must leave Part A unchanged. That is the tech-independence test.)*

---

# The Five Largest Architectural Risks
*(if RAXHA were built exactly from these documents today — ranked)*

1. **Calibration is load-bearing and hard (D18).** The entire stack assumes *calibrated* Confidence flows upward; if per-user, in-the-wild calibration can't be achieved and maintained, the Risk/Policy math is mathematically-optimal but operationally wrong. **Mitigation owed:** calibration + field-monitoring designed in from the Human State Engine outward, not bolted on.
2. **Continuous-sensing starvation on the closed platform.** ADR-004 keeps the *decision* independent, but watchOS background limits can starve the independent engine of *continuous data* — the architecture is independent while the data supply may be platform-gated. **Mitigation owed:** design the engine to be correct on sparse/event-driven input, and make Coverage honest about the gap (D09).
3. **The base-rate wall (D19/D20).** No architecture repeals the base-rate trap; if the real-world false-alarm rate can't be driven low enough, trust erodes and the product fails regardless of design elegance. **Mitigation owed:** the trust-budget policy + shadow-mode + two-sided metrics must prove out on real fleet data before scale.
4. **The dead-man's switch is only as good as the heartbeat (D11).** Distributed truth backstops device failure — but if the heartbeat channel is itself unreliable, coverage gaps hide inside the backstop. **Mitigation owed:** treat heartbeat reliability as a first-class SLO; iOS-first reduces (not eliminates) the OEM/Doze exposure.
5. **You cannot fully measure what you miss (D20).** Drills, shadow mode, and surrogates *estimate* the miss rate; residual epistemic uncertainty about true field misses never fully closes. **Mitigation owed:** institutionalize the estimated-miss surrogates and never let the visible (false-alarm) metric be optimized alone.

---

*Next: **08A** — Subsystem Responsibility Matrix (the one-table onboarding view), then **08B Part B** (domain-object field schemas), then **09** SRS.*
