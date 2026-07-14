# 08A — Subsystem Responsibility Matrix

> **Every subsystem owns exactly one primary responsibility. It may produce evidence for downstream subsystems, but it may never assume responsibilities owned by another subsystem (Doctrine D17).**
>
> The one-page architecture map: keep this open while working. Names are the Blueprint's frozen Part-A names (08); vocabulary is the frozen set (08B Part A). The **Never Owns** column is the drift-prevention contract — a code change that gives a subsystem something from its Never-Owns list is an architecture violation, not a refactor. *Derived From:* 08 Blueprint Part A · ADR-000 · D17.

---

## The Matrix

| Subsystem | Single Responsibility | Owns | **Never Owns** | Inputs | Outputs | Failure Behaviour | Evidence Produced | Upstream | Downstream | ADRs | Doctrine |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Sensing Layer** | **Acquire** trustworthy Evidence | Signal acquisition; quality tagging; platform-detection ingestion (as evidence) | **State estimation · risk · decisions · alerting** | Raw Signals; platform detections; on-body status | Evidence (+Confidence, timestamps) | Emits *"unknown"* low-Confidence Evidence; never fabricates, never silent | SQI per signal; on-body state; acquisition gaps | Human (sensors); platforms | Human State Engine; Coverage Monitor | 001, 004, 011, 013 | D01, D04, D05, D13 |
| **Human State Engine** | **Estimate** the human state | The single canonical fused state + calibrated Confidence; Baseline maintenance | **Risk scoring · decisions · alerting · raw acquisition** | Evidence; Baseline | Human State (+Confidence) | Contradictions → reconciling state; missing modalities widen uncertainty (never default-normal) | Fused state, Confidence, contributing Evidence | Sensing Layer | Risk Engine | 006, 012 | D13, D16, D18 |
| **Risk Engine** | **Quantify** risk | Calibrated Risk (probability + severity), RAXHA's independent judgment | **Alerting · escalation · notification · policy · fusion** | Human State; Candidates; context; Coverage | Risk assessment (+rationale) | Degrades gracefully; one faulty input cannot dominate; never inflates on uncalibrated Confidence | Risk value, Confidence, rationale | Human State Engine | Policy Engine | 002, 004 | D02, D16, D18, D19 |
| **Policy Engine** | **Decide** interruption | The final action decision `{none…escalate}`; cost model; trust budget | **Risk computation · sensor fusion · delivery** | Risk; context; personalization; trust state | Policy Decision (+human-readable rationale) | Deterministic + replayable; context can never veto (D17); low-Confidence + alarming → check-in, never silence | Decision, rationale, trust cost | Risk Engine | Response & Escalation | 008, 009, 014 | D03, D13, D15, D17, D19 |
| **Response & Escalation Engine** | **Execute** the response | Incident lifecycle; countdown; ladder progression; acknowledgment tracking | **Deciding whether to act · risk · state inference** | Policy Decision; contacts config; acknowledgments | Incident (+EscalationState); Alerts | Durable, reboot-recoverable, idempotent; an Alert isn't done until a human acks | Incident timeline, receipts, acks (audit) | Policy Engine | Delivery & Coordination; Responders | 007, 010 | D06, D11 |
| **Coverage Monitor** | **Measure** protection | Coverage state (Protected/Degraded); non-wear detection; coaching triggers | **Detection · decisions · alerting** | On-body, battery, links, pipeline liveness, permissions | Coverage state; nudges | A gap is *surfaced*, never hidden | % protected; gap events; non-wear signals | All tiers (liveness) | Family app; Risk Engine (context) | — | D09, D14 |
| **Delivery & Coordination** (cloud) | **Coordinate** delivery | Multi-contact fan-out; ladder; dead-man's switch; audit; Incident mirror | **Human-state inference · risk estimation · gating the SOS** | Incident events (idempotent); acks; contact graph | Delivered Alerts; escalations; drill results | Persists-before-processing; at-least-once + idempotent; escalates on vanished heartbeat | Delivery SLOs, ack records, drills | Response & Escalation | Responders' devices | 005, 007 | D02, D06, D11 |
| **Privacy/Trust Plane** *(cross-cutting)* | **Minimize** trust | Data-plane enforcement; retention/expiry; minimization | **Any inference or delivery logic** | All data flows | Enforced boundaries; expiring shares | Blocks violating flows (fail-closed for data, never for safety) | Data-flow audit records | — (plane) | — (plane) | 013 | D05, D21 |
| **Model & Threshold Governance** *(cross-cutting)* | **Govern** change | Signed, shadow-tested, canaried, rollback-able model/threshold deploys | **Runtime decisions** | Candidate models/thresholds; shadow + two-sided metrics | Approved, versioned artifacts | A bad artifact is caught pre-fleet (shadow/canary) or rolled back | Deploy records; two-sided metrics; change audit | — (plane) | All inference subsystems | 015 | D08, D20 |

*(Naming note: informal synonyms map as — "Sensor Framework"→Sensing Layer · "Response Engine"→Response & Escalation Engine · "Backend"→Delivery & Coordination · "Observability"→Coverage Monitor + Governance evidence. The left column is canonical; synonyms do not appear in specs or code.)*

---

## Failure Propagation (not every failure propagates the same way — this makes it explicit)

**1. Sensor loss (quality failure → inquiry, not escalation):**
```
Sensing Layer fails → Human State Confidence drops → Risk becomes Unknown-leaning
→ Policy prompts "Are you OK?" (D13) → Response does NOT auto-escalate
→ Coverage Monitor surfaces "Degraded" to family
```

**2. Phone death mid-Incident (device failure → escalation continues):**
```
Phone dies during COUNTDOWN → heartbeat to cloud vanishes
→ Delivery & Coordination's dead-man's switch fires (D11)
→ ladder proceeds server-side → family alerted WITHOUT the phone
```
*(Contrast with #1: sensor uncertainty resolves toward asking; a vanished device mid-incident resolves toward escalating. Uncertainty about the person ≠ loss of the machine.)*

**3. Network loss (connectivity failure → local autonomy):**
```
Network down → decision unaffected (on-device, D02) → local alarm + SMS/voice fallback
→ events queue in outbox → sync on reconnect (idempotent, no duplicates)
```

**4. Bad model/threshold (change failure → contained pre-fleet):**
```
Regressing artifact → shadow mode catches divergence → never reaches canary
(or canary metrics trip → automatic rollback) → fleet never exposed (D08/D20)
```

**5. Non-wear (human failure → coaching, not silence):**
```
Watch off wrist → Coverage Monitor detects → "Degraded" surfaced to wearer + family
→ coaching nudge (D14) → no false pretense of protection (D09)
```

---

*Downstream artifacts (SRS, Hazard Analysis, API specs) MUST use these subsystems and boundaries as given — they do not invent new subsystems or reassign responsibilities. A needed change here is an RFC against the Blueprint, not an edit in a downstream doc.*
