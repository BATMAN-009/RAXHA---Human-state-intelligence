# 08B — Data Dictionary & Controlled Vocabulary

> **Phase-2 artifact — sits between the Subsystem Responsibility Matrix (08A) and the SRS (09).** One glossary, one meaning. Every API, database schema, replay harness, state machine, and test uses **exactly these terms with exactly these definitions.** If engineers start saying "event" in five ways, the architecture decays — so this document is authoritative over vocabulary.
>
> **Status:** Part A (Controlled Vocabulary) is **frozen** (part of the Foundation Lock). Part B (domain-object field schemas) is **complete** (2026-07-14), derived from the Blueprint (08) and Responsibility Matrix (08A). Downstream (SRS, API specs, DB schema, replay harness) implements these objects and never redefines them.

---

## Part A — Controlled Vocabulary (the ladder — FROZEN)

The pipeline reads strictly bottom-to-top; each term is a distinct rung. **Never substitute one rung for another.**

```
Signal → Observation → Evidence → Human State → Risk → Policy Decision → Incident → Alert
```

| Term | Exactly means (one definition) | Never means |
|---|---|---|
| **Signal** | A single **raw** sensor sample (accel reading, PPG sample). Unprocessed, untrusted. | A conclusion; anything validated. |
| **Observation** | A **processed** measurement — filtered value or extracted feature — with quality + timestamp metadata (B5). | Raw data; a decision. |
| **Evidence** | An Observation **validated and admitted into reasoning**, carrying calibrated Confidence (e.g., SQI-passed HR, plausibility-gated heading, **a platform fall detection tagged with reliability**). | A verdict. **Platform detections are Evidence, never authority** (ADR-004). |
| **Anomaly** | A specific Evidence type: a measured **deviation from the person's Baseline** (C11). A candidate signal. | An Emergency. |
| **Candidate** | A flagged **possible event awaiting Risk scoring** (from triggers / anomaly detection). | An Incident; a decision. |
| **Human State** | The **single canonical** fused, calibrated estimate of the person's current physiological + behavioral + contextual state (Human State Engine, ADR-006). | Any single sensor's output. |
| **Risk (Risk Score)** | The **calibrated probability/severity** that a genuine Emergency is occurring, from Human State + Candidates + context (C12). | A raw model score; a decision. |
| **Policy Decision** | The action the **Policy layer** selects given Risk: `{none, observe, check-in, countdown, alert, escalate}` (ADR-014). | The Risk score; the Alert. |
| **Incident** | An **escalation-tracked occurrence**, opened when a Policy Decision decides to act; owns an EscalationState (FSM), an ID, and a lifecycle `open → acknowledged/escalating → resolved` (B1/B10). | A single notification; a real-world emergency. |
| **Emergency** | The **real-world, ground-truth** event (an actual fall/collapse). Used for truth & metrics. | A system object. *(False alarm = Incident, no Emergency. Missed = Emergency, no Incident.)* |
| **Alert** | A **single notification sent to a contact within an Incident** (one Incident → many Alerts across the delivery ladder). | The Incident itself. |
| **Event** | The **durable, idempotent inter-tier message/record** (`EventEnvelope`, B7/B10) persisting "something happened" as it crosses tiers. | Loosely "emergency" or "incident." |
| **Coverage** | The measured state of whether protection is **currently active** (worn + charged + pipeline alive + reachable) — the leading KPI (Doctrine #9). | Detection accuracy. |
| **Baseline** | The person's **personal-normal distribution(s)**, multi-timescale (Doctrine #16; C5/C11). | A population norm. |
| **Confidence** | A **calibrated** probability attached to Evidence / Human State / Risk (Doctrine #18). | An uncalibrated model score. |

**Disambiguation rulings (the collisions that would otherwise rot the architecture):**
- **Incident ≠ Emergency ≠ Alert ≠ Event.** Incident = our tracked response; Emergency = the real-world truth; Alert = one notification within an Incident; Event = a durable inter-tier message.
- **Anomaly ≠ Emergency.** An Anomaly is Evidence/Candidate; it becomes an Incident only through Risk + Policy (Doctrine #17 — the anomaly proposes, Policy disposes).
- **EventEnvelope ≠ AlertEnvelope.** `EventEnvelope` = the generic durable inter-tier message; `AlertEnvelope` = the specific payload delivered to a contact for one Alert.

## Part B — Domain-object field schemas (completed 2026-07-14, derived from Blueprint 08 + Matrix 08A)

> Conceptual schemas — types are logical (`UUID`, `Timestamp{monotonic,wall}`, `Enum`, `0..1`); physical/database and wire encodings belong to artifact 12, which implements these and never redefines them. Standing invariants: every estimate carries `Confidence` (D18); every ID is an idempotency key (D06); **no raw waveform appears in any cloud-crossing object** (D05); location never travels without uncertainty + age (D13/D15).

**`Confidence`** — `{ value: 0..1, calibrationMethod: Enum{temperature, isotonic, none}, calibrationVersion, basis: Enum{measured, inferred, cold_start} }`
A calibrated probability *with provenance*; `none`/`cold_start` are representable and visible downstream — uncalibrated confidence must never masquerade as calibrated.

**`SensorEvidence`** — `{ id: UUID, wearerId, source: Enum{onboard_sensor, platform_detection, derived}, kind: Enum{motion, rotation, orientation, heart_rate, hrv, location, pressure, on_body, platform_fall, …}, value(s) + unit, quality: 0..1 (SQI), confidence: Confidence, measuredAt: Timestamp, receivedAt: Timestamp }`
Staleness = now − `measuredAt`, always computable (measured-time, not received-time). A platform detection is just another `source` — evidence, never authority (ADR-004).

**`Baseline`** — `{ wearerId, signalKind, timescale: Enum{short_days, medium_weeks, long_months}, distribution: {center, spread}, sampleCount, updatedAt, maturity: Enum{cold_start, calibrating, established} }`
One record per (signal × timescale) — the multi-timescale design that keeps slow pathology from hiding in adaptation (D16). Never leaves the device unaggregated (D05/D21).

**`HumanState`** — `{ wearerId, at: Timestamp, posture: Enum{upright, sitting, lying, unknown}, motion: Enum{still, walking, active, vehicle, unknown}, physiology: {hr?, hrDeviationFromBaseline?, …}, placeContext: Enum{home, known, unknown, unavailable}, confidence: Confidence, contributingEvidence: [SensorEvidence.id], baselineMaturity }`
The single canonical estimate (ADR-006). `unknown` is a first-class value in every enum (D13) — absence of evidence is representable, never defaulted to "normal."

**`RiskScore`** — `{ id: UUID, wearerId, at, value: 0..1 (calibrated), severity: Enum{low, moderate, high, critical}, humanStateRef, candidates: [ref], rationale: [factor], modelVersion, thresholdVersion, confidence: Confidence }`
`modelVersion` + `thresholdVersion` are mandatory — both are governed safety artifacts (D20/ADR-015), so every score is traceable to the exact artifacts that produced it.

**`PolicyDecision`** — `{ id: UUID, riskRef, action: Enum{none, observe, check_in, countdown, alert, escalate}, countdownSeconds?, rationale: String (responder vocabulary, D15), policyVersion, decidedAt, trustCost: Enum{none, low, high} }`
Deterministic and replayable (ADR-008): identical inputs ⇒ identical decision, forever.

**`EscalationState`** — `{ state: Enum{IDLE, SUSPECTED, COUNTDOWN, ALERTING, ACKNOWLEDGED, ESCALATING, RESOLVED}, enteredAt, deadlineAt?, seq: Int, fsmVersion }`
Transitions are write-ahead durable and reboot-recoverable (D11); `deadlineAt` is a *persisted timestamp*, never an in-memory timer.

**`Incident`** — `{ id: UUID (idempotency key), wearerId, openedAt, cause: PolicyDecision.id, escalation: EscalationState, stateSnapshot: HumanState, location?: {lat, lon, uncertaintyMeters, ageSeconds, source}, timeline: [transition | alert | ack], resolvedAt?, resolution: Enum{user_cancel, contact_ack, services, timeout_escalated, false_alarm_confirmed} }`
Location embeds **only** with uncertainty + age (D15). `user_cancel`/`false_alarm_confirmed` resolutions feed shadow-mode labels (D08/D20) — the product's operation is its own evidence engine.

**`EventEnvelope`** — `{ eventId: UUID (dedup key), incidentId?, seq: Int, type, payload (events/features only — never raw waveforms, D05), createdAt: Timestamp{monotonic, wall}, deviceId, fsmVersion, ackedAt? }`
The durable inter-tier message; all consumers are idempotent (D06) — a flaky network can replay it harmlessly.

**`AlertEnvelope`** — `{ alertId: UUID, incidentId, contactId, rung: Enum{push, sms, voice}, summary: String (responder vocabulary), locationShare?: {token, expiresAt}, responderCardRef?, sentAt, deliveryReceipt?, acknowledgedAt? }`
One Alert per contact per rung; `locationShare` is token-scoped and expiring (D21); unacknowledged ⇒ the ladder climbs (D06).

**`Contact`** — `{ id, wearerId, name, relationship, channels: [{rung, address, criticalAlertCapable}], escalationOrder: Int, consent: Enum{invited, accepted, declined}, quietHours? }`
A Contact is a *consented* responder — `accepted` is required before any Alert may target them (PDR-011).

**`DeviceCoverage`** — `{ wearerId, at, protection: Enum{protected, degraded, unprotected}, wornState: Enum{worn, off, unknown}, battery: {watch?, phone?}, links: {watchPhone, phoneCloud}, permissions: {location, notifications, health, motion}, gaps: [{from, to, cause}] }`
The Coverage KPI's substrate (D09); every `degraded` is attributable to a `cause` — which is what the coaching hooks (D14) act on.

*Rule: every object above is defined **once**, here. API specs (12), the DB schema, the replay harness, and tests import these names — they do not coin synonyms.*
