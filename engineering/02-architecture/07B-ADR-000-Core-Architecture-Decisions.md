# ADR-000 — Core Architecture Decisions

> **Phase-2 foundational artifact — precedes the Master Architecture Blueprint (08).** These are the **immutable *engineering* constraints** of RAXHA v1: not philosophy (the 22 Doctrine laws and the Canon are that), but the buildable architectural decisions *derived* from them. Every Blueprint diagram, every subsystem, and every later ADR references these by ID. They are **Accepted and stable for v1**; changing one is a deliberate architecture-review event, not a refactor.
>
> **Format:** each ADR states Context → Decision → Consequences (+ / − / forecloses) → *Derives from* (Doctrine #) → *Implemented by* (subsystem). The distinction from doctrine is the point: a doctrine law says *why*; an ADR says *what the architecture must therefore do*.

---

## ADR-001 — Native applications for the safety path
- **Context:** Cross-platform frameworks cannot reliably access the background-execution, sensor, and health machinery a life-critical path needs; they also raise App/Play-review and hiring risk.
- **Decision:** The sensing, risk, and escalation code is **native** — Swift/SwiftUI (iOS/watchOS), later Kotlin/Compose (Android/Wear OS). Non-critical surfaces *may* use other tech; the safety path never does.
- **Consequences:** + platform-correct reliability; + hireable expertise. − two codebases (mitigated by ADR-011's shared pure core). Forecloses: a single cross-platform safety codebase.
- **Derives from:** Doctrine #1. **Implemented by:** Watch app, Phone app, Sensor adapters.

## ADR-002 — RAXHA owns an independent Risk Engine
- **Context:** If a platform detector (or any single vendor) were the decision-maker, RAXHA would be a wrapper that breaks when that vendor changes.
- **Decision:** RAXHA runs its **own deterministic risk-assessment engine**. It is the core asset; everything else is an interface around it.
- **Consequences:** + survives vendor/API changes; + the moat is ownable. − RAXHA must build and validate real assessment logic, not just integrate. Forecloses: "RAXHA = a nicer UI over Apple fall detection."
- **Derives from:** Doctrine #2, #17. **Implemented by:** Risk Engine (core).

## ADR-003 — Offline-first
- **Context:** A promise that requires connectivity is not a promise; emergencies happen where networks fail.
- **Decision:** **Local storage/state is the source of truth; the network is an enhancement that syncs.** No safety decision awaits the network.
- **Consequences:** + graceful degradation by construction. − sync/reconciliation complexity. Forecloses: cloud-dependent decision paths.
- **Derives from:** Doctrine #2. **Implemented by:** On-device FSM, durable journal, outbox.

## ADR-004 — Platform detections are evidence, never authority
- **Context:** Platform signals (e.g., Apple `CMFallDetectionManager`) are valuable but out of RAXHA's control and semantics.
- **Decision:** Platform detections enter the Risk Engine as **evidence inputs with confidence**, fused with RAXHA's own signals; RAXHA makes the escalation decision.
- **Consequences:** + best-of-both (use platform strength, keep independence). − must model platform-signal reliability. Forecloses: treating any external signal as the verdict.
- **Derives from:** Doctrine #2, #17; PRD §1. **Implemented by:** Risk Engine, Sensor/Platform adapters.

## ADR-005 — The cloud never gates the SOS decision
- **Context:** Life-critical latency and availability cannot depend on a round-trip.
- **Decision:** The SOS **decision** is made on-device. The cloud coordinates, delivers, and provides the dead-man's switch — it never decides *whether* to alert.
- **Consequences:** + works offline; + low latency. − richer cloud models can only *assist post-hoc*, not gate. Forecloses: server-side decisioning in the critical path.
- **Derives from:** Doctrine #2, #11. **Implemented by:** Risk Engine (device), Backend (coordination only).

## ADR-006 — One canonical Human State Engine
- **Context:** Scattering detection/decision logic per-feature produces inconsistent, untestable behavior.
- **Decision:** A **single Human State Engine** produces the canonical (state + calibrated confidence) estimate that all features consume; features do not each invent their own state logic.
- **Consequences:** + consistency, one place to test/validate/calibrate. − must design a general state representation. Forecloses: per-feature bespoke detection silos.
- **Derives from:** mission; C10, C12. **Implemented by:** Human State Engine (fusion → state).

## ADR-007 — The Backend is response/coordination, not inference
- **Context:** Inference belongs on-device (ADR-005); the cloud's job is reliable delivery.
- **Decision:** The Backend does **ingest → durable queue → escalation orchestration → delivery ladder → dead-man's switch → audit** — and **no life-critical inference**.
- **Consequences:** + a boring, provable, auditable backend; + privacy (no raw data needed server-side). − no "smart cloud" shortcuts. Forecloses: cloud-side emergency detection.
- **Derives from:** Doctrine #2, #5; B10. **Implemented by:** Backend.

## ADR-008 — Deterministic, replayable escalation FSM (no LLM in the decision path)
- **Context:** A life-critical decision must be reproducible, testable, and auditable; LLMs are none of those.
- **Decision:** Escalation is an explicit **finite state machine** with durable, write-ahead transitions and **replayable** determinism. Detection = deterministic logic + validated ML; **never an LLM.** LLMs only explain/summarize/assist.
- **Consequences:** + testable via replay; + reboot-survivable. − no generative flexibility in the decision. Forecloses: probabilistic/LLM decisioning in the critical path.
- **Derives from:** Doctrine #3; C12; Competency 2. **Implemented by:** Escalation FSM (core).

## ADR-009 — Every life-critical decision is explainable and auditable
- **Context:** Users, families, clinicians, and regulators must be able to ask *why it alerted*.
- **Decision:** Every escalation decision emits a **human-readable rationale** (in responder vocabulary) and an immutable audit record.
- **Consequences:** + trust, debuggability, regulatory readiness. − constrains opaque models at the decision layer. Forecloses: black-box life-critical decisions.
- **Derives from:** Doctrine #15, #18; C12. **Implemented by:** Decision Engine, Audit log.

## ADR-010 — No single subsystem or device owns truth
- **Context:** Any single device's storage can be unreadable/unavailable exactly when needed (reboot, dead battery, offline).
- **Decision:** Life-critical state is **distributed**: boot-readable on-device journal + cloud FSM mirror (dead-man's switch) + (where hardware allows) watch autonomy. No component is the sole authority.
- **Consequences:** + survives any single failure. − reconciliation + idempotency required everywhere. Forecloses: single-source-of-truth for safety state.
- **Derives from:** Doctrine #11. **Implemented by:** Device journal, Backend FSM mirror, Watch.

## ADR-011 — Hexagonal core (pure domain + ports & adapters)
- **Context:** Testability, cross-platform reuse, and replay all require decoupling logic from the OS.
- **Decision:** The Risk/State/FSM core is **pure** (zero platform imports); all I/O crosses **ports** implemented by **adapters** (real in production, recorded/fake in tests). Dependency Inversion is the load-bearing principle.
- **Consequences:** + one core, two platforms; + replay CI; + swappable tech (ADR Part B). − discipline to keep the core pure. Forecloses: platform code in the domain.
- **Derives from:** Doctrine #10; B13. **Implemented by:** `RaxhaCore`, all adapters.

## ADR-012 — Confidence is calibrated and propagated end-to-end
- **Context:** Fusion and risk are only as good as the calibration of their inputs; uncalibrated confidence is worse than none.
- **Decision:** Every estimate carries **calibrated** uncertainty; it propagates through fusion → risk → policy; calibration is monitored in the field.
- **Consequences:** + honest, decision-theoretic risk. − must build calibration + monitoring. Forecloses: bare point-estimates in the decision path.
- **Derives from:** Doctrine #13, #18; C10, C12. **Implemented by:** Human State Engine, Risk Engine.

## ADR-013 — Data plane: raw stays on device; privacy by architecture
- **Context:** The most sensitive data a person emits must not be centralized; privacy must be structural, not promissory.
- **Decision:** **Raw waveforms live and die on the watch; features cross to the phone; only events cross to the cloud.** Location is incident-only, expiring, token-scoped. No sellable data store exists.
- **Consequences:** + battery, privacy, and "can't misuse what we don't hold" solved by one rule. − richer cloud analytics forgone. Forecloses: central raw-sensor/location database; data monetization.
- **Derives from:** Doctrine #5, #21. **Implemented by:** all tiers; Backend schema.

## ADR-014 — Context adjusts confidence but never vetoes a life-critical event
- **Context:** Well-meaning "people don't fall while driving" rules silently suppress real emergencies (car/motorcycle/cycling crashes).
- **Decision:** Context signals may **raise or lower** confidence; a context signal may **never independently zero-out** a life-critical event. This is an enforced, tested invariant.
- **Consequences:** + no silent suppression. − accepts more low-confidence checks over missed events. Forecloses: context-as-veto code paths.
- **Derives from:** Doctrine #17. **Implemented by:** Decision Engine (policy).

## ADR-015 — Thresholds and models are governed safety artifacts
- **Context:** A threshold or model change silently alters clinical behavior; missed-emergency regressions leave no telemetry.
- **Decision:** Models **and thresholds** ship only via **signed, canaried, shadow-tested, rollback-able** deploys, with two-sided (false-alarm + estimated-miss) monitoring and change audit.
- **Consequences:** + no silent unsafe drift. − heavier release process. Forecloses: ad-hoc threshold/model edits in production.
- **Derives from:** Doctrine #20; B8/B9/B12. **Implemented by:** Model/threshold registry, CI, Observability.

---

## Immutability & traceability policy
- These 15 ADRs are **v1-stable**. The Blueprint (08) references them by ID per subsystem (e.g., *Risk Engine implements ADR-002, -004, -006, -008, -012, -014*). Detailed, expandable ADRs for narrower decisions live later in the sequence (artifact 11) and must not contradict ADR-000.
- Traceability chain (06 §5): **Doctrine law → ADR-00X → Blueprint component → SRS requirement → validation test.** Nothing in the architecture is arbitrary; everything traces up to a doctrine law and down to a test.

---

## Appendix A — Decision Traceability Matrix

> Every canonical decision (D01–D22, the single index) → where it is **enforced**, how it is **validated**, and its **evidence**. No decision is left as "philosophy." *In Canon* = ✓ for all 22 (Canon realigned 2026-07-14). Test IDs are **planned placeholders**; real IDs are assigned in the V&V Plan (artifact 13) — they do not yet imply existing tests (Doctrine D08/D20 honesty).

| Doctrine | In Canon | Enforced by | Subsystem | Validation method | Test (→13) | Evidence |
|---|:---:|---|---|---|---|---|
| **D01** Native safety layer | ✓ | ADR-001 | All native apps | Build / platform check | VV-D01 | B2, B3 |
| **D02** On-device risk engine / cloud never gates | ✓ | ADR-002, ADR-005 | Risk Engine (on-device) | Replay (offline decision) | VV-D02 | B1, B10 |
| **D03** No LLM in detection path | ✓ | ADR-008 | Decision Engine | Code audit + replay determinism | VV-D03 | C12 |
| **D04** Tier autonomy | ✓ | ADR-003, ADR-010 | All tiers | Chaos (kill each tier) | VV-D04 | B1, B7 |
| **D05** Data plane | ✓ | ADR-013 | Data plane (all tiers) | Data-flow + schema audit | VV-D05 | C13, B1 |
| **D06** Delivery contract (at-least-once + idempotent) | ✓ | ADR-007 | Backend delivery | Duplicate-delivery replay | VV-D06 | B10 |
| **D07** Latency budgeted | ✓ | *(process; Doctrine §3)* | Pipeline (all stages) | Latency regression | VV-D07 | B12, §3 |
| **D08** Shadow mode before live | ✓ | ADR-015 | Release / Observability | Shadow-mode release gate | VV-D08 | B12 |
| **D09** Coverage telemetry (first KPI) | ✓ | *(Observability)* | Coverage subsystem | Coverage-telemetry test | VV-D09 | B1, B12 |
| **D10** Architecture before code | ✓ | *(process — this Phase 2)* | Governance | Doc-existence gate | — | B14 |
| **D11** No single source of truth | ✓ | ADR-010 | Device journal + Backend FSM mirror | Reboot-mid-incident replay + dead-man drill | VV-D11 | C2/3, B10 |
| **D12** Three truths | ✓ | *(discipline)* | All | Doc/label audit | VV-D12 | Doctrine |
| **D13** Absence of evidence ≠ evidence of absence | ✓ | ADR-012 | Human State Engine + Risk | Low-confidence-alarming-context replay | VV-D13 | C4, C12 |
| **D14** Non-wear is top field failure | ✓ | *(product; PDR + Coverage)* | Coverage + Product UX | Non-wear detection test | VV-D14 | C4 |
| **D15** Responder vocabulary | ✓ | ADR-009 | Decision Engine output + Family app | Content / UX audit | VV-D15 | C7, C12 |
| **D16** Classify changes, not people | ✓ | ADR-006 | Human State Engine (Baseline) + Anomaly | Baseline-deviation replay | VV-D16 | C5, C8, C11 |
| **D17** Hierarchy / veto contract | ✓ | ADR-014 | **Policy / Decision Engine** | Veto-contract scenario replay | VV-D17 | C12 |
| **D18** Calibrated confidence | ✓ | ADR-012 | Human State Engine + Risk | Calibration test (ECE / reliability) | VV-D18 | C10 |
| **D19** Appropriate interruption (trust budget) | ✓ | *(Policy)* | Policy Engine | FA/person-week + trust-budget test | VV-D19 | C11, C12 |
| **D20** Missed emergencies invisible / govern thresholds | ✓ | ADR-015 | Model/Threshold registry + Observability | Two-sided metric + synthetic drill | VV-D20 | C12, B12 |
| **D21** Privacy = trust-minimization | ✓ | ADR-013 | Privacy (all tiers) | Pen test + data audit | VV-D21 | C13, B11 |
| **D22** The Boundary (not a physician) | ✓ | **PDR-005** + Policy | Product + Policy Engine | Boundary / content audit | VV-D22 | C15 |

*Corollaries inherit their parent's row: veto contract → D17; contradiction-is-information → D18; every-claim-carries-evidence → D21; measurement-is-not-meaning → D22.*
*Corrections vs. the illustrative example: D22 enforced by PDR-005 + Policy (not ADR-013); D17 subsystem is Policy/Decision Engine (not Risk Engine).*
