# 09 — System Requirements Specification (SRS)

> **RAXHA v1** (iPhone + Apple Watch, per PDR-002/PDR-004). This SRS converts the locked foundation — North Star, PRD (07), PDR-000 (07A), ADR-000 (07B), Blueprint (08), Responsibility Matrix (08A), Data Dictionary (08B) — into **numbered, verifiable requirements**. It invents no subsystems and reassigns no responsibilities (08A is authoritative); it introduces no vocabulary (08B Part A is authoritative). A conflict with a frozen document is an RFC, never an edit (00A).
>
> **Conventions.** `SHALL` = mandatory, verified before release; `SHOULD` = expected, deviations documented. IDs are stable (`SRS-###`) — cited by the Hazard Analysis (10), API specs (12), V&V (13), and code. **Verification methods:** `Replay` (recorded/synthetic traces through the real pipeline), `Chaos` (fault injection), `Drill` (synthetic end-to-end fleet incident), `Measure` (instrumented metric vs target), `Audit` (inspection of code/data/copy), `Shadow` (silent field evaluation). Every requirement names one.

---

## 1. Sensing Layer (SEN)

| ID | Requirement | Derived From | Verify |
|---|---|---|---|
| SRS-101 | The system SHALL acquire motion, heart-rate, on-body, and location Evidence tagged with `measuredAt`, quality (SQI), and `Confidence`, per the `SensorEvidence` schema. | 08A; 08B; D05 | Replay |
| SRS-102 | The system SHALL ingest platform fall detections as `SensorEvidence` with `source=platform_detection` — treated as evidence with reliability, never as an authoritative decision. | ADR-004; PRD §4.1 | Replay |
| SRS-103 | On sensor loss or low quality, the Sensing Layer SHALL emit low-Confidence/"unknown" Evidence; it SHALL NOT fabricate values and SHALL NOT go silent. | D13; 08A | Chaos |
| SRS-104 | All Evidence timestamps SHALL be normalized to a single monotonic timeline before any fusion; staleness SHALL be computable for every value. | 08B; B5 | Replay |
| SRS-105 | Raw waveforms SHALL NOT leave the device on which they were captured; only Evidence/features SHALL cross to the phone, and only Events to the cloud. | D05; ADR-013 | Audit |

## 2. Human State Engine (HSE)

| ID | Requirement | Derived From | Verify |
|---|---|---|---|
| SRS-201 | The system SHALL maintain exactly one canonical `HumanState` per wearer, fused from Evidence + Baseline, carrying calibrated `Confidence`. | ADR-006, ADR-012; D18 | Replay |
| SRS-202 | Missing or low-quality modalities SHALL widen `HumanState` uncertainty; the engine SHALL NOT default any unknown to "normal." | D13 | Replay |
| SRS-203 | The system SHALL maintain per-wearer multi-timescale Baselines (short/medium/long) and score deviation against all timescales, so slow decline cannot be absorbed by short-term adaptation. | D16; 08B | Shadow |
| SRS-204 | Baseline maturity (`cold_start/calibrating/established`) SHALL be tracked and exposed; cold-start wearers SHALL be treated with widened uncertainty and the calibrating state surfaced honestly. | D13, D16 | Audit |
| SRS-205 | Emitted Confidence SHALL be calibrated (a stated 70% correct ≈70% of the time), with calibration monitored in the field against shadow ground truth. | D18 | Shadow + Measure |

## 3. Risk Engine (RSK)

| ID | Requirement | Derived From | Verify |
|---|---|---|---|
| SRS-301 | The system SHALL compute its own Risk assessment on-device; no cloud call SHALL be required for, or capable of gating, the risk computation. | ADR-002, ADR-005; D02 | Chaos (offline) |
| SRS-302 | Every `RiskScore` SHALL record the `modelVersion` and `thresholdVersion` that produced it. | D20; ADR-015; 08B | Audit |
| SRS-303 | A single faulty or implausible input SHALL NOT dominate the Risk output (cross-sensor consistency / outlier rejection). | 08 Blueprint A3; D11 | Replay (spoofed-input traces) |
| SRS-304 | Risk SHALL be personalized: baseline deviation and context SHALL modulate the assessment per-wearer (population priors initialize; personal models govern). | D16 | Shadow |

## 4. Policy Engine (POL)

| ID | Requirement | Derived From | Verify |
|---|---|---|---|
| SRS-401 | The Policy Engine SHALL be the only component that converts Risk into action, selecting from `{none, observe, check_in, countdown, alert, escalate}`. | D17; 08A | Audit + Replay |
| SRS-402 | Policy decisions SHALL be deterministic and replayable: identical inputs SHALL produce identical decisions; no LLM SHALL participate in the decision path. | ADR-008; D03 | Replay (determinism) |
| SRS-403 | Context SHALL only raise or lower confidence/risk; no context signal SHALL independently suppress a life-critical event (the veto contract). A code path enabling context-veto is prohibited. | D17; ADR-014 | Replay (veto suite) + Audit |
| SRS-404 | When measurement confidence is low AND context is alarming, the system SHALL resolve toward a low-cost check-in ("Are you OK?"), never toward silence. | D13 | Replay |
| SRS-405 | Every Policy Decision SHALL emit a human-readable rationale in responder vocabulary (no raw sensor values in user-facing text). | D15; ADR-009 | Audit |
| SRS-406 | The countdown SHALL be user-cancelable with an elder-accessible control (large target, loud escalating alarm, haptics); cancellation SHALL be recorded as a shadow label. | PRD §4.4; D08/D20 | Audit + Replay |
| SRS-407 | Recent false alarms SHALL make escalation *more* conservative (trust-budget awareness), within safety floors. | D19 | Shadow |

## 5. Response & Escalation Engine (RES)

| ID | Requirement | Derived From | Verify |
|---|---|---|---|
| SRS-501 | Every escalation SHALL be tracked as an `Incident` with a durable, write-ahead `EscalationState`; all transitions SHALL survive process death and device reboot, resuming with correct remaining time from persisted timestamps. | D11; ADR-010; 08B | Chaos (reboot mid-COUNTDOWN) |
| SRS-502 | The minimal FSM journal SHALL be readable immediately after reboot (boot-readable storage) and SHALL contain no sensitive payload; sensitive data SHALL be fetched from protected storage at send time. | D11, D21; C2/C3 | Chaos + Audit |
| SRS-503 | All Incident/Alert processing SHALL be idempotent: replayed or duplicated events SHALL NOT produce duplicate Alerts or duplicate escalations. | D06; 08B | Chaos (duplicate injection) |
| SRS-504 | If the countdown expires while the device was dead/offline, the system SHALL fail toward alerting (with the coverage gap annotated), never toward silent abandonment. | D13; C2 gate | Chaos |
| SRS-505 | An unacknowledged Alert SHALL climb the delivery ladder (push → SMS → voice) and then the contact order; an Incident is not resolved until acknowledged, resolved by the wearer, or exhausted per policy. | D06; PRD §4.6 | Drill |

## 6. Delivery & Coordination — cloud (DEL)

| ID | Requirement | Derived From | Verify |
|---|---|---|---|
| SRS-601 | The cloud SHALL persist every inbound Incident event durably *before* any processing; a downstream outage SHALL NOT lose an alert. | ADR-007; B10 | Chaos |
| SRS-602 | The cloud SHALL maintain an Incident mirror with a dead-man's switch: an active Incident whose device heartbeat vanishes SHALL be escalated server-side without device participation. | D11; ADR-010 | Drill (kill device mid-incident) |
| SRS-603 | The cloud SHALL perform no human-state inference and SHALL NOT gate the SOS decision; its scope is coordination, delivery, acknowledgment, audit. | ADR-005, ADR-007; D02 | Audit |
| SRS-604 | Alert delivery SHALL use multi-vendor failover for SMS/voice; a single vendor outage SHALL NOT prevent delivery. | B10; 08 risks | Chaos |
| SRS-605 | A synthetic end-to-end drill (device → cloud → delivery → acknowledgment) SHALL run at least daily per fleet; a failed drill SHALL page as a Sev-1. | D20; B12 | Drill + Measure |

## 7. Coverage Monitor (COV)

| ID | Requirement | Derived From | Verify |
|---|---|---|---|
| SRS-701 | The system SHALL continuously compute `DeviceCoverage` (protected/degraded/unprotected) with an attributable cause for every degradation, and SHALL surface it to wearer and family; a coverage gap SHALL never be hidden. | D09; 08B | Measure + Audit |
| SRS-702 | Non-wear and chronic poor contact SHALL be detected and SHALL trigger coaching to wearer and/or family *before* an emergency (configurable quiet hours respected). | D14; PRD §4.8 | Shadow + Audit |
| SRS-703 | Every partial-permission state SHALL map to an explicit, honestly-labeled protection level shown to the user; no permission denial may silently reduce protection. | D13; PRD §9 | Audit |

## 8. Cross-cutting: Privacy & Security (PRV)

| ID | Requirement | Derived From | Verify |
|---|---|---|---|
| SRS-801 | Server-side location SHALL exist only for active Incidents, shared via short-lived token-scoped expiring links, purged on resolution; no server-side movement/health history SHALL be accumulated. | D21; ADR-013; B6 | Audit + Pen test |
| SRS-802 | Location SHALL never appear in URL query strings and SHALL never be sent to endpoints not configured by the user. | D21; system doctrine | Audit |
| SRS-803 | Keys SHALL be hardware-backed (Secure Enclave) and non-exportable; safety-critical configuration (models, thresholds) SHALL be signature-verified before activation. | B11; ADR-015 | Pen test + Audit |
| SRS-804 | The schema SHALL make data monetization structurally impossible: no sellable location/sensor history store SHALL exist. | D21; PDR-008 | Audit |
| SRS-805 | Contacts SHALL have consented (`accepted`) before receiving any Alert. | 08B `Contact`; PDR-011 | Audit |

## 9. Cross-cutting: Governance & Observability (GOV)

| ID | Requirement | Derived From | Verify |
|---|---|---|---|
| SRS-901 | Models AND decision thresholds SHALL deploy only via signed, shadow-tested, canaried, rollback-capable releases with documented rationale; ad-hoc production changes are prohibited. | D20; ADR-015 | Audit |
| SRS-902 | New detectors/models SHALL run in shadow mode on fleet data, with real-world false-positive rate known, before being permitted to alert. | D08 | Shadow |
| SRS-903 | False-alarm rate (per wearer-week) AND an estimated-miss surrogate SHALL be monitored together; optimizing the visible metric alone is prohibited. | D20 | Measure |
| SRS-904 | Every life-critical decision SHALL produce an immutable audit record sufficient to reconstruct *why* it was made (inputs, versions, rationale). | ADR-009; D15 | Audit |
| SRS-905 | The quantized/converted on-device model artifact (not merely the float training model) SHALL be validated on the rare-event class before release. | B8/B9; D20 | Replay (int8 artifact) |

## 10. Performance & Reliability (PERF)

| ID | Requirement | Derived From | Verify |
|---|---|---|---|
| SRS-1001 | The on-device detection pipeline (Evidence → Policy Decision), excluding deliberate countdown, SHALL complete within 500 ms (p99). | D07; Doctrine §3 | Measure |
| SRS-1002 | Decision → first responder notification dispatch SHALL meet a seconds-class p99 target (numeric target set and tracked in V&V; measured, not averaged). | D07; B10 SLOs | Measure |
| SRS-1003 | The fall path SHALL maintain a pre-event buffer such that the confirmer sees ≥10 s before trigger; pre-event data loss at trigger is a defect. | C1; B5 | Replay |
| SRS-1004 | Always-on sensing SHALL fit a battery budget compatible with all-day wear (per-mode budget table maintained and regression-tested; gyro/GPS/PPG duty-cycled per the power hierarchy). | Doctrine §3; A-chapters | Measure |
| SRS-1005 | All safety-critical behavior SHALL be exercisable in CI via the replay harness (recorded + synthetic traces, including reboot/duplicate/offline cases) with the veto-contract suite as a release gate. | ADR-008/011; B12 | Replay (CI gate) |

## 11. Product Constraints (CON)

| ID | Requirement | Derived From | Verify |
|---|---|---|---|
| SRS-1101 | v1 SHALL target iPhone + Apple Watch, native (Swift/SwiftUI); no cross-platform framework SHALL be used in the safety path. | PDR-002/004; D01; ADR-001 | Audit |
| SRS-1102 | v1 escalation SHALL be family-only; RAXHA SHALL NOT auto-dial emergency services (native platform SOS remains available to the wearer). | PDR-003 | Audit |
| SRS-1103 | All user-facing claims SHALL conform to the Boundary (detect/notify; never diagnose/treat/prevent) and the exact coverage-promise wording. | D22; PDR-005/007 | Audit (content) |
| SRS-1104 | The wearer-side experience SHALL function with near-zero wearer interaction after family-led setup (elder-invisible constraint). | PRD §2/§7; North Star | Audit + usability |

---

**Traceability:** every SRS ID above chains upward (Derived From → PDR/ADR/D## → North Star) and downward (Hazard Analysis 10 references SRS IDs as mitigations; V&V 13 assigns each `VV-` test to its SRS; the Traceability Matrix in 07B Appendix A binds D## → subsystem → test). A requirement without a verification method, or a verification without a requirement, is a defect in *this* document.

*Next artifacts: `03-safety/10-HAZARD-ANALYSIS.md` (FMEA + STPA over these subsystems, citing SRS IDs as controls), then detailed ADRs (11), API specs (12) implementing 08B, V&V (13) assigning real test IDs, roadmap (14).*
