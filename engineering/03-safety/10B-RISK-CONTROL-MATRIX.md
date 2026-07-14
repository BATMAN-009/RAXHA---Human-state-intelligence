# 10B — Risk Control Matrix

> **Purpose:** for every hazard in [10A](10A-SYSTEM-HAZARD-ANALYSIS.md), exactly *what prevents, detects, or mitigates it* — the safety-traceability document. Control **Type**: `P` prevent (stops occurrence) · `D` detect (reveals occurrence) · `M` mitigate (limits harm). **Implemented By** = subsystem/ADR (08A boundaries); **Verified By** = SRS requirement (+ V&V test to be assigned in 13). **Residual risk** is the honest remainder *after* controls — for the top hazards it is reduced, monitored, and never claimed eliminated.
>
> Rule inherited from 10A: a hazard marked **not naturally observable** MUST have at least one `D`-control of the *manufactured-evidence* kind (drill / replay / shadow / audit). That rule is checked below.

---

## H-01 — Missed emergency *(initial: Critical)*

| Control | Type | Implemented By | Verified By |
|---|---|---|---|
| Multi-signal cascade: platform detection + own trigger + posture/inactivity corroboration (no single-sensor dependence) | P | Sensing + HSE + Risk (ADR-004/006) | SRS-102, 303 |
| "Unknown ≠ normal": missing/low-quality modalities widen uncertainty; low-confidence + alarming context → check-in, never silence | P | HSE + Policy (D13) | SRS-202, 404 |
| **Veto contract:** context may never independently suppress a life-critical event | P | Policy (ADR-014) | SRS-403 + veto replay suite (SRS-1005) |
| Multi-timescale baselines (slow decline cannot normalize into the baseline) | P | HSE (D16) | SRS-203 |
| Threshold governance: changes replayed/canaried/rollback-able with documented rationale | P | Governance (ADR-015, D20) | SRS-901 |
| Reboot/process-death recovery: durable FSM resumes; expired-while-dead fails toward alerting | M | Response & Escalation (D11) | SRS-501, 504 |
| Cloud dead-man's switch escalates on vanished mid-incident heartbeat | M | Delivery & Coordination (ADR-010) | SRS-602 + drill |
| **Manufactured evidence:** replay corpus incl. soft-fall/atypical traces; daily synthetic fleet drill; shadow-mode miss surrogates; two-sided FA+miss monitoring | **D** | Governance + Delivery (D08/D20) | SRS-605, 902, 903, 905 |
| Coverage-equity monitoring of training/personalization data (representation bias) | P | Governance (D21 corollary) | SRS-903 + model cards (13) |

**Residual: Medium — monitored, never claimed eliminated.** Soft-fall detection remains partially open science (C1/C15 evidence gap); residual risk is disclosed in claims (PDR-007 wording promises confidence-gated notification, not "always detect").

## H-02 — False emergency *(initial: High)*

| Control | Type | Implemented By | Verified By |
|---|---|---|---|
| Cascade + context gating (activity/place/physiology reconciliation — the treadmill class) | P | HSE + Risk (C10) | SRS-303, 304 |
| Calibrated confidence into a decision-theoretic threshold (asymmetric cost model) | P | Risk + Policy (D18/D19) | SRS-205, 402 |
| User-cancelable countdown with elder-accessible cancel (the human FA filter) | M | Response UX (PRD §4.4) | SRS-406 |
| Trust-budget conservatism after recent FAs (within safety floors) | M | Policy (D19) | SRS-407 |
| Shadow mode before any detector goes live (real-world FA rate known first) | P | Governance (D08) | SRS-902 |
| FA/wearer-week telemetry + cancellations as labeled data | D | Coverage/Governance | SRS-903 |
| **Guard:** FA-reduction changes must pass the paired miss-surrogate check (no silent H-01 trade) | P | Governance (D20) | SRS-901, 903 |

**Residual: Medium** (target FA/wearer-week set in V&V; the H-02↔H-01 coupling is permanently monitored, never optimized one-sided).

## H-03 — Delayed response *(initial: High)*

| Control | Type | Implemented By | Verified By |
|---|---|---|---|
| Location pre-warming during suspected/armed states (no cold-fix wait at alert time) | P | Sensing (C6 §13) | SRS-1002 path test |
| Send-then-refine: last-known location immediately, updates as fix improves | M | Response & Escalation | SRS-505 payload behavior |
| Persist-before-process ingest; durable queue; retry with backoff | P | Delivery (ADR-007) | SRS-601 |
| Acknowledgment-driven ladder with per-rung timeouts (push is an attempt, not delivery) | M | Delivery (D06) | SRS-505 |
| Multi-vendor SMS/voice failover | M | Delivery | SRS-604 + chaos |
| p99 latency instrumentation per stage + regression gates (tail, not average) | D | All (D07) | SRS-1001, 1002 |

**Residual: Low-Medium** (network reality; bounded by fallbacks and measured tails).

## H-04 — Silent coverage loss *(initial: Critical)*

| Control | Type | Implemented By | Verified By |
|---|---|---|---|
| Continuous DeviceCoverage computation with cause-attributable degradation | D | Coverage Monitor (D09) | SRS-701 |
| Family-visible Protected/Degraded/Alerting status (assurance is a product surface) | M | Family app (PRD §7) | SRS-701 UX audit |
| Non-wear detection + proactive coaching (wearer and family), quiet-hours aware | P | Coverage (D14) | SRS-702 |
| Permission-state monitoring; every partial grant maps to an honest labeled protection level | D | Coverage (D13) | SRS-703 |
| Heartbeats watch→phone→cloud; missing heartbeat is itself a signal | D | All tiers → Delivery | SRS-602 |
| **Manufactured evidence:** daily drill exercises the whole pipeline — a dead pipeline is discovered today, not at the next emergency | **D** | Delivery + Governance | SRS-605 |
| Elder-invisible design + normal-watch form factor (attacks the stigma root cause) | P | Product (PRD §2) | SRS-1104 |

**Residual: Medium.** Non-wear can be reduced and *made visible*, not abolished — residual risk is transferred into honest awareness (family sees the gap) rather than false assurance.

## H-05 — Location unavailable/wrong *(initial: High)*

| Control | Type | Implemented By | Verified By |
|---|---|---|---|
| Registered home address as the honest indoor answer (the common case) | M | Response payload (C6 §13) | PRD §11; payload audit |
| Uncertainty + age attached to every location, end to end (schema-enforced) | P | 08B `Incident.location` (D15) | SRS-104; schema audit |
| Honest presentation: "last known · Xs ago · ±Ym" — never a bare confident pin | M | Family app (D15) | UX content audit (SRS-1103 class) |
| Accuracy-implausibility rejection (multipath jumps downweighted) | P | Sensing (C6) | Replay w/ corrupted fixes |
| Approximate-grant detection → degrade honestly | D | Coverage (SRS-703) | SRS-703 |
| Expiring share-link health-checked at send time | D | Delivery | SRS-801 + drill click-through |

**Residual: Medium** (indoor physics is unfixable in v1; the control is honesty + the home-address fallback, per C7's expectation-engineering answer).

## H-06 — Duplicate escalation *(initial: Medium)*

| Control | Type | Implemented By | Verified By |
|---|---|---|---|
| Idempotency keys end-to-end (`eventId`/`alertId` dedup at every consumer) | P | Response + Delivery (D06) | SRS-503 + duplicate-injection chaos |
| Write-ahead FSM journal dedups re-entry after crash/reboot | P | Response (D11) | SRS-501 |
| Device↔cloud escalation reconciliation (dead-man's switch checks device-sent state before duplicating) | P | Delivery (ADR-010) | SRS-602 reconciliation case |
| Dedup-hit + duplicate-complaint telemetry | D | Delivery | SRS-903-class metric |

**Residual: Low.**

## H-07 — Wrong recipient *(initial: Medium)*

| Control | Type | Implemented By | Verified By |
|---|---|---|---|
| Consent gate: `accepted` required before any Alert targets a contact | P | 08B `Contact` (PDR-011) | SRS-805 |
| Escalation-order as versioned, validated configuration (policy-as-data) | P | Delivery routing | Config audit |
| Per-wearer routing isolation (multi-elder households) | P | Delivery | Routing replay |
| Audit log of every Alert's target + ack source (unexpected-ack anomaly flag) | D | Delivery (ADR-009) | SRS-904 |
| Incident-scoped, expiring shares bound to intended contacts only | M | Privacy plane (D21) | SRS-801 |

**Residual: Low.**

## H-08 — Loss of evidence *(initial: Medium)*

| Control | Type | Implemented By | Verified By |
|---|---|---|---|
| Write-ahead durable journal for every FSM transition | P | Response (D11) | SRS-501 |
| Immutable decision audit with model/threshold versions recorded per decision | P | Governance + Delivery (ADR-009/015) | SRS-302, 904 |
| Determinism gate: replay must reproduce decisions bit-for-bit in CI | P | Policy (ADR-008) | SRS-402, 1005 |
| **Manufactured evidence:** drills verify the audit trail end-to-end (evidence-completeness is itself drilled) | **D** | Delivery + Governance | SRS-605 + audit-completeness check |
| Monotonic-normalized timestamps (event ordering survives clock chaos) | P | Sensing/B5 rule | SRS-104 |

**Residual: Low.**

## H-09 — Privacy breach *(initial: High)*

| Control | Type | Implemented By | Verified By |
|---|---|---|---|
| Data-plane minimization: raw never leaves device; events-only to cloud (nothing waveform-shaped to breach) | P | Privacy plane (ADR-013, D05) | SRS-105 + data-flow audit |
| Incident-only location retention; purge on resolution; no movement/health history store (nothing sellable exists — structural non-monetization) | P | Delivery schema (D21) | SRS-801, 804 |
| Token-scoped expiring shares; no location in URLs/logs | P | Privacy plane | SRS-802 |
| Hardware-backed non-exportable keys; signed safety-config | P | Security (B11, ADR-015) | SRS-803 |
| Consented-recipient-only data flow (no injection-directed delivery) | P | Delivery + Privacy | SRS-805 + system doctrine |
| **Manufactured evidence:** scheduled pen tests, data-flow audits, breach drills | **D** | Security program | SRS-803 + 13 schedule |
| FL (when it ships) only with secure aggregation + bounded disclosed ε — never naive | P | Governance (C13) | Pre-ship gate in 13 |

**Residual: Low-Medium** (industry-standard breach risk remains; the architectural bet is that *what doesn't exist can't leak* — minimization is the dominant control).

---

## Residual-risk register (post-controls)

| Hazard | Initial → Residual | Accepted because |
|---|---|---|
| H-01 Missed emergency | Critical → **Medium, monitored** | Residual is science-limited (soft falls), disclosed in claims (PDR-007), and permanently surveilled via manufactured evidence |
| H-04 Silent coverage loss | Critical → **Medium, visible** | Converted from *silent* to *surfaced*: the residual gap is known to the family, which is the honest form of the risk |
| H-02 False emergency | High → Medium | Coupled-metric governance prevents one-sided optimization |
| H-03 Delayed response | High → Low-Medium | Tail-measured, fallback-bounded |
| H-05 Location wrong/absent | High → Medium | Physics-limited indoors; honesty + fallback is the ceiling for v1 |
| H-09 Privacy breach | High → Low-Medium | Minimization removes the asset class |
| H-06 / H-07 / H-08 | Medium → **Low** | Engineering-solvable; controls are conventional and testable |

**Sign-off rule:** no hazard ships at residual **High/Critical**; `No`-observable hazards ship only with their manufactured-evidence controls verified in V&V (13). This matrix + 10A constitute the seed of the ISO-14971 Risk Management File (B14) and are inputs to every V&V test-ID assignment.

*Next: 11 — Detailed ADRs, 12 — API/Interface Specs (implementing 08B), 13 — V&V (assigns `VV-` IDs to every "Verified By" above), 14 — Implementation Roadmap.*
