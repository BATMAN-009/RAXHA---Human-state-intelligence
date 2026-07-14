# 11 — Detailed Architecture Decision Records (ADR-101…ADR-112)

> **Numbering:** foundational decisions are **ADR-001…015** (frozen in [07B](../02-architecture/07B-ADR-000-Core-Architecture-Decisions.md)); this document is the **100-series** — one ADR per subsystem (101–107, mirroring [08A](../02-architecture/08A-SUBSYSTEM-RESPONSIBILITY-MATRIX.md)) plus cross-cutting concerns (108–112). A 100-series ADR *expands* foundational decisions for one owner; it may never contradict ADR-000 (that would be an RFC against the locked foundation, 00A).
>
> **Template (rigid):** Problem · Decision · Context · Alternatives Considered (incl. **Rejected** + reason) · Trade-offs · Consequences · Failure Modes · Verification · Related Doctrine · Related SRS · Related Hazards · Supersedes. Deliberately absent: implementation code, APIs, diagrams — those live in 12/implementation. An ADR answers *why this decision is correct*, not *how to build it*.
>
> **The traceability chain these complete:** `Hazard → ADR → SRS → VV` — e.g., **H-01 → ADR-104 → SRS-403 → VV-D17**. V&V (13) then "writes itself": every test verifies that implementation satisfied ADR → SRS → hazard control.

---

## ADR-101 — Sensing Layer: event-driven, quality-first acquisition
- **Problem:** continuous multi-sensor acquisition is battery-impossible and privacy-hostile; naive acquisition delivers unusable data (mixed clocks, silent gaps, no quality).
- **Decision:** acquisition is **event-driven and power-tiered** (always-on accelerometer gates gyro/GPS/PPG), delivering Evidence under a fixed contract: measured-time on a normalized monotonic timeline, quality (SQI) attached at source, gaps explicit, staleness computable. Platform detections enter as `source=platform_detection` Evidence.
- **Context:** power hierarchy (µA accel → mA gyro → tens-of-mW GPS/PPG); wrist-site signal realities; platform background limits.
- **Alternatives — Rejected:** *Continuous all-sensor streaming* (battery-fatal; violates D05 data plane). *HealthKit background delivery as the live emergency wire* (system-scheduled latency violates D07 — it is a store, not a wire; B4). *Raw-data uplink for cloud processing* (violates D05/D02; adds a network dependency to safety).
- **Trade-offs:** event-driven capture risks missing pre-trigger context → paid for with the always-on ring buffer; tiered wake adds latency line-items (gyro spin-up) → budgeted, measured.
- **Consequences:** all-day battery viability; every downstream consumer can trust timestamps/quality; sensors can be swapped behind ports.
- **Failure Modes:** silent sample drops (→ gap markers + coverage telemetry); clock-domain mixing (→ single-normalization rule); trigger-buffer underrun (→ SRS-1003).
- **Verification:** SRS-101…105, 1003 (Replay + Chaos + Audit).
- **Related Doctrine:** D01, D04, D05, D07, D13. **Related SRS:** 101–105, 1003. **Related Hazards:** H-01, H-04, H-05. **Supersedes:** — (expands ADR-001/-004/-011/-013).

## ADR-102 — Human State Engine: one canonical estimate over multi-timescale baselines
- **Problem:** scattered per-feature state logic produces contradictory, untestable behavior; single-rate baselines either normalize slow pathology or false-alarm on healthy change.
- **Decision:** exactly **one** fused `HumanState` (with calibrated Confidence) consumed by all features; personal Baselines maintained at **three timescales** (days/weeks/months) with deviation scored against all; `unknown` is a first-class value in every dimension; contradictory evidence resolves to a *reconciling hypothesis*, never an average.
- **Context:** C10 fusion, C11 anomaly (multi-timescale answer from the Competency-11 gate), C5/C8 baselines; Decision D16.
- **Alternatives — Rejected:** *Per-feature state estimates* (inconsistency; violates ADR-006). *Population-norm baselines as the judge* (violates D16 — classify changes, not people). *Silently discarding low-quality inputs* (violates D13 — absence must widen uncertainty, not vanish).
- **Trade-offs:** a general state representation costs design effort up front; multi-timescale storage/compute is 3× a single baseline → accepted for the pathology-can't-hide property.
- **Consequences:** one place to test, calibrate, and validate; personalization is structural; every consumer inherits honesty about unknowns.
- **Failure Modes:** baseline poisoning via over-fast adaptation (→ bounded rates + cross-timescale check); cold-start overconfidence (→ maturity field + widened uncertainty).
- **Verification:** SRS-201…205 (Replay + Shadow).
- **Related Doctrine:** D13, D16, D18. **Related SRS:** 201–205. **Related Hazards:** H-01, H-02. **Supersedes:** — (expands ADR-006/-012).

## ADR-103 — Risk Engine: decision-theoretic, versioned, independent
- **Problem:** binary emergency classification ignores asymmetric costs (a miss is catastrophic; a false alarm erodes trust) and single-vendor detection makes RAXHA a wrapper.
- **Decision:** Risk is a **calibrated probability + severity computed on-device by RAXHA's own engine**, under an explicit asymmetric cost model, with personalized context-dependent thresholds; every score stamps `modelVersion` + `thresholdVersion`; implausible single inputs are rejected via cross-sensor consistency.
- **Context:** C12 (decision theory, NEWS2 lineage), C1 base-rate, ADR-002/-004; Blueprint risk #3.
- **Alternatives — Rejected:** *Binary classifier* ("emergency yes/no" collapses the cost asymmetry — C12). *Thresholding uncalibrated scores* (violates D18 — mathematically optimal, operationally lethal). *Cloud-side risk computation* (violates D02/ADR-005 — adds network to the decision).
- **Trade-offs:** calibration and per-user thresholds are ongoing work, not a one-time model → accepted; independence means RAXHA must validate its own judgment (shadow mode) rather than inherit Apple's.
- **Consequences:** the decision survives any vendor change; every score is auditable to the artifacts that made it; threshold changes become governable objects.
- **Failure Modes:** miscalibration drift (→ ADR-108 field monitoring); threshold drift under FA pressure (→ ADR-112 governance; C12 standing answer).
- **Verification:** SRS-301…304 (Replay incl. spoofed-input traces; Shadow).
- **Related Doctrine:** D02, D16, D18, D19. **Related SRS:** 301–304. **Related Hazards:** H-01, H-02. **Supersedes:** — (expands ADR-002/-004).

## ADR-104 — Policy Engine: deterministic graded policy with a structural veto ban
- **Problem:** the conversion of risk into action is where lives are decided; it must be correct, explainable, replayable — and protected from the slow organizational drift of context-suppression rules.
- **Decision:** a **deterministic, replayable policy** selects from graded actions `{none, observe, check_in, countdown, alert, escalate}`; context enters **only** as a confidence/risk modifier — **no code path exists by which a context signal can zero out a life-critical event** (the veto contract, enforced structurally, reviewed, and release-gated by a replay suite); low-confidence + alarming context resolves to check-in; recent false alarms raise conservatism within safety floors; every decision emits a responder-vocabulary rationale.
- **Context:** D17's corollary (Competency-9 gate: "context becoming an unintended veto" as the top field failure), D19 trust budget, C12.
- **Alternatives — Rejected:** *Allow context to suppress falls* ("people don't fall while driving" — violates D17; car/motorcycle/cycling crashes are why it's lethal). *LLM-in-the-decision* (violates D03 — unreproducible, unauditable). *End-to-end learned policy* (unexplainable and unreplayable; violates D15/ADR-008 and the accountability capstone).
- **Trade-offs:** deterministic policy over a probabilistic score sacrifices some theoretical optimality for auditability → the correct trade for the layer that bears moral responsibility.
- **Consequences:** identical inputs ⇒ identical decisions forever; the veto ban is testable, not aspirational; regulators/families/clinicians can be shown *why*.
- **Failure Modes:** threshold/policy drift (→ ADR-112); rationale rot (rationales stop matching logic → rationale is generated from the same decision inputs, audited).
- **Verification:** SRS-401…407, 1005 (Replay determinism + veto suite as CI release gate).
- **Related Doctrine:** D03, D13, D15, D17, D19. **Related SRS:** 401–407, 1005. **Related Hazards:** H-01, H-02. **Supersedes:** — (expands ADR-008/-009/-014).

## ADR-105 — Response & Escalation: durable, idempotent, fail-toward-alerting
- **Problem:** the escalation machine must survive the worst minute of the system's life — crash, reboot, dead battery, flaky links — without losing, duplicating, or silently abandoning an emergency.
- **Decision:** the Incident FSM is **write-ahead durable with persisted deadlines** (timestamps, never in-memory timers); the minimal journal (IDs, states, timestamps — no sensitive payload) lives in **boot-readable storage** with sensitive data fetched from protected storage at send time; all processing is **idempotent** by EventEnvelope/Alert IDs; a countdown that expired while the device was dead **fails toward alerting** with the gap annotated.
- **Context:** Competency-2/3 gates (reboot-mid-COUNTDOWN; `afterFirstUnlock` insufficiency; Direct-Boot split), D11 distributed truth.
- **Alternatives — Rejected:** *In-memory countdown timers* (reboot silently abandons the emergency — the C2 gate's exact failure). *Protected-class storage for the journal* (unreadable precisely when recovery needs it — C2/C3). *At-most-once delivery* (loses alerts; violates D06). *Fail-toward-silence on expired-while-dead* (violates D13's asymmetric default).
- **Trade-offs:** boot-readable journal trades a sliver of confidentiality (mitigated: no sensitive fields) for availability in the exact scenario that matters; idempotency adds bookkeeping everywhere → non-negotiable for a safety system.
- **Consequences:** the emergency is never forgotten by any single failure; duplicates are structurally impossible; recovery is testable in milliseconds via fake clocks.
- **Failure Modes:** journal corruption (→ integrity via hardware-backed signing or cloud-authoritative copy — C3 resolution); double-escalation with the dead-man's switch (→ reconciliation, ADR-106).
- **Verification:** SRS-501…505 (Chaos: reboot/duplicate/offline; Drill).
- **Related Doctrine:** D06, D11, D13. **Related SRS:** 501–505. **Related Hazards:** H-01, H-03, H-06, H-08. **Supersedes:** — (expands ADR-007/-010).

## ADR-106 — Delivery & Coordination: persist-first orchestration, never inference
- **Problem:** the cloud must guarantee delivery and backstop device death without ever becoming a decision-maker or a data honeypot.
- **Decision:** ingest **persists before processing**; an orchestrated **ladder** (push → SMS → voice, per contact, ack-driven fallthrough) with **multi-vendor failover**; a **dead-man's switch** escalates on vanished mid-incident heartbeats *after reconciling device-sent state* (no duplicate escalation); scope is delivery/coordination/audit **only** — no human-state inference, no SOS gating.
- **Context:** B10, ADR-005/-007, D11; H-06 reconciliation need.
- **Alternatives — Rejected:** *Fire-and-forget push* (push is an attempt, not delivery — documented unreliability). *Single telephony vendor* (SPOF in the harm path). *"Smart cloud" risk enrichment* (scope creep into inference; violates ADR-007/D02 and creates a data-gravity honeypot).
- **Trade-offs:** a deliberately "boring" backend forgoes clever server-side features → boring is the achievement; multi-vendor costs integration effort → bought reliability.
- **Consequences:** an alert survives any single vendor, process, or device failure; the backend is provable (drills) and privacy-cheap (events only).
- **Failure Modes:** ladder stall (→ per-rung timeouts + SLOs); dead-man false-fire on healthy-but-disconnected devices (→ reconciliation + heartbeat SLO; Blueprint risk #4).
- **Verification:** SRS-601…605 (Chaos + daily Drill as Sev-1 gate).
- **Related Doctrine:** D02, D06, D11. **Related SRS:** 601–605. **Related Hazards:** H-01, H-03, H-06, H-07. **Supersedes:** — (expands ADR-005/-007/-010).

## ADR-107 — Coverage Monitor: protection is a measured, surfaced product state
- **Problem:** the believed-protected-but-isn't state (H-04) is Critical and, by default, silent; non-wear is the documented #1 field killer.
- **Decision:** coverage is **continuously computed with an attributable cause** for every degradation, **surfaced to wearer and family** as a first-class product state (Protected/Degraded/Alerting), with **proactive coaching** on non-wear/battery/permissions; every partial-permission state maps to an explicit, honestly-labeled protection level.
- **Context:** D09 (coverage = first KPI), D14 (non-wear), D13 (honest absence); PRD's Coverage Assurance differentiator.
- **Alternatives — Rejected:** *Silent degradation* ("don't worry users with gaps" — violates D09/D13 and converts H-04 into H-01 with betrayed trust). *Coverage as internal-only telemetry* (assurance is the *product* for the family buyer — PRD §3/§7).
- **Trade-offs:** surfacing gaps creates support/anxiety load → mitigated by coaching UX and attributable causes ("not worn since 1pm" beats "something's wrong").
- **Consequences:** the residual H-04 risk is converted from silent to visible — its honest form; coverage becomes the leading KPI before any emergency ever occurs.
- **Failure Modes:** nagging → muted nudges (→ quiet-hours + coaching-rate limits); coverage computation itself dies silently (→ watchdogged by the daily drill).
- **Verification:** SRS-701…703 (Measure + Audit + Shadow).
- **Related Doctrine:** D09, D13, D14. **Related SRS:** 701–703. **Related Hazards:** H-04 (owner), H-01. **Supersedes:** — (new subsystem detail under D09/D14).

## ADR-108 — Calibration (cross-cutting): confidence is a maintained instrument
- **Problem:** the whole stack (fusion → risk → policy) consumes Confidence; if stated probabilities aren't true frequencies, the math is optimal and the outcome lethal (Blueprint risk #1).
- **Decision:** every emitted Confidence carries **calibration provenance**; per-population (later per-user) **post-hoc calibration** (temperature/isotonic) is applied and **field-monitored** against shadow-mode ground truth (reliability diagrams, ECE); recalibration is a governed change (ADR-112); `cold_start/none` states are representable and visibly propagate.
- **Context:** D18, C10 (the Competency-10 standing answer: calibration as the most likely field failure).
- **Alternatives — Rejected:** *Raw model scores as probabilities* (violates D18). *One-time calibration at release* (drift guarantees decay; field recalibration or bust). *Hiding uncalibrated states* (violates D13/D18 honesty — downstream must see `basis`).
- **Trade-offs:** calibration infrastructure (ground truth, monitoring, recalibration pipeline) is permanent operational cost → it is the tax on making Risk mean something.
- **Consequences:** "70% confident" is auditable; Policy thresholds sit on solid ground; the Blueprint's #1 risk gets a standing countermeasure.
- **Failure Modes:** ground-truth scarcity (→ shadow labels + drill outcomes as proxies); silent calibration decay (→ scheduled reliability checks with alert thresholds).
- **Verification:** SRS-205 + calibration monitors (Measure/Shadow).
- **Related Doctrine:** D13, D18. **Related SRS:** 205, 903. **Related Hazards:** H-01, H-02. **Supersedes:** — (expands ADR-012).

## ADR-109 — Replay & Determinism (cross-cutting): the rare event must be testable forever
- **Problem:** the events that matter most (falls, reboots mid-incident) cannot be waited for or ethically produced; without determinism, no failure is reproducible and no fix is provable.
- **Decision:** the decision core is **pure and hexagonal** (every I/O behind a fakeable port, including the clock); a **versioned trace corpus** (recorded + synthetic: soft falls, ADLs, reboots, duplicates, offline, veto scenarios) runs through the *real* pipeline in CI as a **release gate**; the **shipped quantized artifact** (not the float model) is what gets validated; identical inputs must reproduce identical decisions bit-for-bit.
- **Context:** ADR-008/-011, B12; H-01/H-08's `No`-observability demanding manufactured evidence.
- **Alternatives — Rejected:** *Device-only/manual testing* (cannot exercise rare events repeatably). *Nondeterministic concurrency in the decision path* (breaks replay; violates ADR-008). *Validating the float model only* (quantization silently degrades the rare class — B8/B9).
- **Trade-offs:** purity discipline and corpus curation are ongoing costs → they are also the entire basis of regulatory verification evidence (B14: CI-as-evidence).
- **Consequences:** "reboot at T+10s" is a millisecond-fast CI case; every hazard control marked `Replay` in 10B is executable; V&V inherits an evidence engine.
- **Failure Modes:** corpus rot/unrepresentativeness (→ shadow-mode traces feed the corpus; lab-vs-life gap tracked); determinism erosion (→ bit-exactness check in CI).
- **Verification:** SRS-402, 905, 1003, 1005 (Replay as CI gate).
- **Related Doctrine:** D03, D08, D20. **Related SRS:** 402, 905, 1003, 1005. **Related Hazards:** H-01, H-08. **Supersedes:** — (expands ADR-008/-011).

## ADR-110 — Observability (cross-cutting): manufacture the missing telemetry, watch both sides
- **Problem:** the worst hazards produce no natural telemetry (H-01, H-04, H-08); optimization pressure therefore flows toward the loud metric (false alarms) and silently degrades the quiet one (misses) — the D20 asymmetry.
- **Decision:** observability is **two-sided by construction**: FA/wearer-week AND estimated-miss surrogates are monitored *together* and released *together*; **daily synthetic fleet drills** exercise device→cloud→delivery→ack (failure = Sev-1); coverage KPI is continuous; latency is tracked at **p99**; all telemetry is **privacy-preserving** (aggregates/events, never raw streams).
- **Context:** D09/D20, B12, the 10A observability column's headline finding.
- **Alternatives — Rejected:** *FA-only dashboards* (structurally guarantees the C12 threshold-drift failure). *Average-latency SLOs* (the tail is the product — D07). *Raw-stream telemetry for debuggability* (violates D05/D21 — observability must not become surveillance).
- **Trade-offs:** miss-surrogates are estimates, not truth (Blueprint risk #5) → accepted and stated; drills cost fleet noise → scheduled and invisible to users.
- **Consequences:** a broken pipeline is discovered *today*; a threshold change that trades misses for quiet is visible at review time; the org's incentive gradient is corrected structurally.
- **Failure Modes:** surrogate divergence from true misses (→ periodic re-anchoring via drills + reported events); drill blindspots (→ drill scenarios rotate).
- **Verification:** SRS-605, 701, 903, 1001–1002 (Drill + Measure).
- **Related Doctrine:** D07, D09, D20. **Related SRS:** 605, 701, 903, 1001, 1002. **Related Hazards:** H-01, H-02, H-04, H-08. **Supersedes:** — (expands ADR-015's monitoring half).

## ADR-111 — Privacy (cross-cutting): minimization as the dominant control
- **Problem:** RAXHA handles the most intimate data a person emits; policy promises don't survive breaches, acquisitions, or incentives (the Life360 lesson); privacy failure is existential-trust failure (H-09).
- **Decision:** privacy is **architectural trust-minimization**: raw dies on-device; events-only cross to cloud; **incident-only location retention** with purge-on-resolve; **token-scoped expiring shares**; hardware-backed non-exportable keys; **no store of sellable location/health history exists** (structural non-monetization); consent gates on every recipient; future federated learning ships only with secure aggregation + bounded, disclosed ε.
- **Context:** D05/D21, C13, B11, B6; PDR-008 (privacy as differentiator must be architecturally true).
- **Alternatives — Rejected:** *Central history "for future features"* (creates the breachable/sellable/subpoenable asset — the Life360 anti-pattern; violates D21). *Plaintext server-side processing for convenience* (honeypot; violates minimization). *Naive federated learning* (gradient inversion/membership inference — C13; FL-alone is not privacy).
- **Trade-offs:** minimization forgoes server-side analytics and some product convenience → that forgone capability *is* the trust guarantee ("we can't misuse what we never hold").
- **Consequences:** the breach blast-radius is structurally small; the privacy marketing claim is provable; regulators see minimization posture (C15).
- **Failure Modes:** scope creep re-centralizing data (→ data-flow audit as release check; RFC required to add any store); share-link leakage (→ expiry + no-URL-location rule).
- **Verification:** SRS-105, 801–805 (Audit + Pen test + drills).
- **Related Doctrine:** D05, D21, D22-adjacent. **Related SRS:** 105, 801–805. **Related Hazards:** H-07, H-09. **Supersedes:** — (expands ADR-013).

## ADR-112 — Model & Threshold Governance (cross-cutting): clinical-grade change control
- **Problem:** a model *or threshold* change silently alters life-critical behavior; missed-emergency regressions leave no telemetry; ad-hoc production tuning is how safety products drift unsafe (the C12 standing answer).
- **Decision:** models **and thresholds** are versioned safety artifacts shipping only via **signed → shadow-tested → canaried → rollback-capable** releases with documented rationale; every Risk/Policy output stamps the versions that produced it; release gates require the **paired two-sided metric check** (no FA improvement may ship with a degraded miss-surrogate); the change-control shape is PCCP-compatible (B14) for the future cleared-claim path.
- **Context:** D08/D20, ADR-015, B8/B9/B12/B14; H-01's governance controls.
- **Alternatives — Rejected:** *Hotfix threshold edits in production* (the exact drift mechanism of the C12 gate answer; violates D20). *Unversioned models* (breaks audit + H-08). *Cleared-claim ambitions without PCCP-shaped control* (every update would be a new submission — B14).
- **Trade-offs:** release velocity is deliberately sacrificed for safety governance → for thresholds this feels heavy and is exactly the point.
- **Consequences:** no silent unsafe drift; the audit chain (decision → artifact versions → change rationale) is complete; the regulatory pathway stays open.
- **Failure Modes:** governance bypass under incident pressure (→ kill-switches are governed too; emergency changes still logged + retro-reviewed); canary blindness to rare events (→ shadow duration sized to event rarity).
- **Verification:** SRS-302, 901–903, 905 (Audit + Shadow + Measure).
- **Related Doctrine:** D08, D20. **Related SRS:** 302, 901–903, 905. **Related Hazards:** H-01, H-02, H-08. **Supersedes:** — (expands ADR-015).

---

## Rejected-Alternatives Register (the "don't re-litigate" index)

| Rejected | Reason | ADR |
|---|---|---|
| Continuous all-sensor streaming | Battery-fatal; D05 | 101 |
| HealthKit background delivery as live wire | System-scheduled latency; D07 | 101 |
| Per-feature state estimates | Inconsistent, untestable; ADR-006 | 102 |
| Population-norm judging individuals | D16 | 102 |
| Binary emergency classification | Ignores asymmetric costs; C12 | 103 |
| Uncalibrated-score thresholds | D18 | 103 |
| Cloud-side risk computation | D02 | 103 |
| **Context allowed to suppress a fall** | **D17 veto contract** | 104 |
| LLM in the decision path | D03 | 104 |
| End-to-end learned policy | Unexplainable/unreplayable; D15 | 104 |
| In-memory countdown timers | Reboot abandons the emergency; C2 | 105 |
| Protected-class journal storage | Unreadable when needed; C2/C3 | 105 |
| At-most-once delivery | Loses alerts; D06 | 105 |
| Fire-and-forget push | Push is an attempt, not delivery | 106 |
| Single telephony vendor | SPOF in the harm path | 106 |
| "Smart cloud" inference | ADR-007/D02 scope creep | 106 |
| Silent coverage degradation | D09/D13; converts H-04 → H-01 | 107 |
| One-time calibration | Drift; D18 | 108 |
| Float-model-only validation | Quantization hits the rare class; B8 | 109 |
| FA-only dashboards | Guarantees threshold drift; D20 | 110 |
| Average-latency SLOs | The tail is the product; D07 | 110 |
| Central data history "for later" | The Life360 anti-pattern; D21 | 111 |
| Naive federated learning | Gradient inversion; C13 | 111 |
| Hotfix production thresholds | The C12 drift mechanism; D20 | 112 |

*A future proposal matching a rejected row is not forbidden — it requires an RFC that overturns the recorded reason, knowingly.*
