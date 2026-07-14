# 10A — System Hazard Analysis (STPA + FMEA)

> **Purpose:** identify and analyze the hazards of RAXHA v1 — *why each hazard exists*. Controls live in **[10B — Risk Control Matrix](10B-RISK-CONTROL-MATRIX.md)** (this doc analyzes; 10B traces prevention/detection/mitigation). Organized around **unsafe outcomes for the wearer and family**, not around components — a sensor failure only matters through the outcome it can cause (ISO 14971 / STPA orientation).
>
> **Scales.** Severity: S4 catastrophic (death/serious injury) · S3 major (delayed care, significant harm) · S2 moderate (distress, trust damage, privacy harm) · S1 minor. Probability: qualitative High/Med/Low **with stated basis — pre-deployment estimates, to be replaced by shadow-mode field data** (D08; honesty per the Confidence Ledger). Detectability: how evident the hazard is *when it occurs*. **Observable in production?** — `Yes` (direct telemetry) / `Partially` (surrogate metrics) / **`No` (requires drills/replay/shadow — these hazards MUST have manufactured evidence, D20).**
>
> *Derived From:* 08 Blueprint (A8 failure propagation, closing risks) · 08A (failure behaviours) · 09 SRS · D11/D13/D17/D19/D20/D21 · the Academy's ~26 chapter failure tables (lineage cited per hazard).

---

## STPA control structure (the frame)

The safety-critical **controller** is the Policy Engine; its **control action** is the escalation decision `{none…escalate}` executed by Response & Escalation. The four STPA unsafe-control-action (UCA) classes map onto the hazard set:

| UCA class | Meaning here | Hazards |
|---|---|---|
| **Not provided** when needed | No Incident for a real Emergency | H-01 |
| **Provided** when not needed | Incident/Alerts without an Emergency | H-02 |
| **Too late / too early** | Right action, wrong time | H-03 |
| **Wrong sequence / duration / target** | Ladder, dedup, recipient, payload errors | H-04…H-07 |

(H-08, H-09 are process/data hazards outside the control loop but inside ISO 14971 scope.)

---

## H-01 — Missed emergency *(the defining hazard)*
- **UCA:** alert **not provided** when a real Emergency exists.
- **Failure modes / causes:** signal never captured (non-wear → but see H-04; sensor gap; watch off-body) · Evidence captured but state mis-estimated (soft/syncope fall with no impact signature — C1 §14; PPG signal-loss misread as artifact — C4) · Risk under-scored (miscalibration — C10; population model on atypical individual — C8/C13 representation bias; **baseline slowly normalizes decline** — C11 multi-timescale gap) · Policy wrongly suppressed (**context-veto drift** — C9 "unintended veto"; **threshold drift under false-alarm pressure** — C12 standing answer) · decision made but never delivered (reboot mid-COUNTDOWN — C2; process death; ladder stall — see H-03).
- **Harm:** wearer remains without help → injury progression, death. **Severity: S4.**
- **Probability:** Med (basis: documented real-world miss modes in fall-detection literature — SisFall→FARSEEING gap; syncope falls; estimate, pre-deployment).
- **Detectability at occurrence:** very poor — *this hazard produces no natural telemetry* (D20).
- **Initial risk:** **Critical (S4 × Med)** — the top-ranked hazard.
- **Observable in production? — NO.** Requires replay corpus, synthetic drills, shadow-mode surrogates, user/family-reported misses (D20 manufactured evidence).
- **Subsystems:** all (Sensing → Delivery). **Doctrine:** D13, D16, D17, D20. **SRS:** 103, 202, 203, 303, 403, 404, 501, 504, 602, 903, 905.
- **Academy lineage:** C1 (base-rate & soft falls), C4 (loss-of-signal vs loss-of-pulse), C9 (context veto), C11 (baseline normalization; multi-timescale fix), C12 (threshold drift), C13 (FL representation bias), C2/C3 (reboot recovery).

## H-02 — False emergency
- **UCA:** alert **provided** when no Emergency exists.
- **Failure modes / causes:** impact-like ADLs (sit-down-hard, sports — C1) · treadmill-class context misses (C10) · PPG artifact read as physiology (C4) · miscalibrated confidence inflating Risk (C10/D18) · population baseline judging an atypical-normal individual (C8) · duplicate-triggering defects (see H-06).
- **Harm:** family panic, needless dispatch, and — chronically — **alarm fatigue: contacts mute/ignore/disable → converts into H-01** (the documented pendant/clinical-alarm death spiral). **Severity: S3** (acute) escalating to S4-equivalent via the H-01 conversion.
- **Probability:** High untreated (basis: C1's 302-FA/week arithmetic; treated with the cascade+context stack: Med, to be measured in shadow).
- **Detectability:** good — cancellations and family feedback are loud.
- **Initial risk:** **High.**
- **Observable in production? — YES** (cancel rate, FA/wearer-week, ack behavior). *The trap: because H-02 is loud and H-01 is silent, optimization pressure flows toward fixing H-02 at H-01's expense — the two hazards must always be tuned together (D20, SRS-903).*
- **Subsystems:** Sensing, HSE, Risk, Policy. **Doctrine:** D18, D19, D20. **SRS:** 303, 304, 402, 406, 407, 903.
- **Academy lineage:** C1 (base-rate trap), C4 (artifact), C10 (calibration, treadmill), C12 (trust budget).

## H-03 — Delayed response
- **UCA:** alert provided **too late** to be useful.
- **Failure modes / causes:** cold GPS fix at alert time (C6 — mitigated by pre-warming) · ladder stalls (push treated as delivered; vendor outage — B10) · queue/retry pathologies · countdown longer than context warrants (policy tuning) · watch→phone→cloud link outages serializing retries · background throttling delaying the pipeline (B2/B3).
- **Harm:** help arrives late; outcome worsens. **Severity: S3–S4** (time-critical events).
- **Probability:** Med (basis: platform background-execution variability, network reality).
- **Detectability:** good *if measured as p99* — averages hide the tail.
- **Initial risk:** **High.**
- **Observable in production? — YES** (trigger→ack p99, per-rung latency), **but only if percentile-instrumented** (SRS-1002).
- **Subsystems:** Response & Escalation, Delivery & Coordination, Sensing (location). **Doctrine:** D06, D07. **SRS:** 505, 601, 604, 1001, 1002.
- **Academy lineage:** C6 (cold-fix latency, pre-warm), B10 (ladder/SLOs), B2/B3 (background execution).

## H-04 — Silent coverage loss *(the believed-protected hazard)*
- **UCA context:** the control loop is **absent while believed present**.
- **Failure modes / causes:** non-wear (charger, stigma, comfort — the pendant killer) · OS kills the pipeline (Doze/background — B2/B3) · permission silently revoked (location/notifications/health) · battery death · link down (phone away) · sensor degradation unnoticed.
- **Harm:** wearer and family carry false assurance; any Emergency in the gap becomes H-01 **with the added harm of betrayed trust**. **Severity: S4** (it converts directly into missed emergencies).
- **Probability:** High untreated (basis: non-wear is the documented #1 field failure — D14).
- **Detectability:** poor *by default* — that is the hazard's definition; good once Coverage telemetry exists.
- **Initial risk:** **Critical.**
- **Observable in production? — PARTIALLY** (coverage telemetry directly observes worn/link/battery/permission state — SRS-701 — but "user *believes* protected" requires UX audit + drills to confirm the surfacing actually lands).
- **Subsystems:** Coverage Monitor (owner), all tiers (sources). **Doctrine:** D09, D13, D14. **SRS:** 701, 702, 703.
- **Academy lineage:** C4 standing answer (non-wear as top field failure → D14), Ch 1.1 Historian (pendant non-wear), B2/B3 (OS killers).

## H-05 — Location unavailable or wrong
- **UCA class:** control action with **wrong payload** (responder misdirected or blind).
- **Failure modes / causes:** indoor GPS unavailability (the common home case — C6) · confident-wrong urban multipath fix (C6) · stale last-known presented as current (C6/B5 staleness) · approximate-permission grant treated as precise (B6) · location share expired/broken at responder click.
- **Harm:** responders delayed or misdirected; search burden on family. **Severity: S3.**
- **Probability:** High for the *indoor-unavailable* case (basis: physics — C6 §3.3); Low-Med for confident-wrong outdoors.
- **Detectability:** moderate (accuracy/age are known at send time — the hazard is *presenting* them dishonestly).
- **Initial risk:** **High.**
- **Observable in production? — PARTIALLY** (uncertainty/age telemetry yes; "responder was actually misdirected" only via incident review).
- **Subsystems:** Sensing (location), Response & Escalation (payload), family app (presentation). **Doctrine:** D13, D15. **SRS:** 104, 803(share), 1002; PRD §11 honest-location UX.
- **Academy lineage:** C6 (multipath, indoor, staleness, registered-address fallback), C7 (indoor ambiguity — the standing answer on expectation engineering).

## H-06 — Duplicate escalation
- **UCA class:** control action **repeated** (wrong duration/sequence).
- **Failure modes / causes:** at-least-once redelivery without idempotent consumption · retry storms after link flaps · FSM re-entry after crash/reboot without journal dedup · both device and dead-man's switch escalating without reconciliation.
- **Harm:** family terror ("five calls at 3am"), dispatch confusion, trust erosion (spends the D19 budget on nothing). **Severity: S2–S3.**
- **Probability:** High untreated (basis: distributed-systems certainty — retries happen); Low with idempotency keys.
- **Detectability:** good (duplicate alert IDs are directly countable).
- **Initial risk:** **Medium.**
- **Observable in production? — YES** (dedup-hit metrics, duplicate-complaint rate).
- **Subsystems:** Response & Escalation, Delivery & Coordination. **Doctrine:** D06, D11. **SRS:** 503, 601, 602 (reconciliation).
- **Academy lineage:** C2 (idempotent event IDs — the original gate answer), B7/B10 (EventEnvelope, ladder).

## H-07 — Wrong recipient notified
- **UCA class:** control action to the **wrong target**.
- **Failure modes / causes:** stale/misconfigured contact data · escalation-order bugs · un-consented contact alerted (consent state ignored) · cross-wearer routing defects (multi-elder families) · responder-card/location shared beyond the incident's contacts.
- **Harm:** privacy exposure of health+location to an unintended party; the *right* contact not reached (→ H-03/H-01). **Severity: S3** (privacy + response failure).
- **Probability:** Low-Med (basis: configuration and routing defects are ordinary software risk).
- **Detectability:** moderate (acks from unexpected parties; complaints).
- **Initial risk:** **Medium.**
- **Observable in production? — PARTIALLY** (routing logs auditable; "wrongness" often needs human report).
- **Subsystems:** Delivery & Coordination (routing), Response & Escalation (targeting). **Doctrine:** D21, D22-adjacent (data to responders is *information sharing*). **SRS:** 805, 604, 904.
- **Academy lineage:** B10 (contact/consent model), PDR-011.

## H-08 — Loss of evidence
- **UCA class:** process hazard — *the system cannot prove why it acted or failed to act.*
- **Failure modes / causes:** journal loss on crash/reboot (non-durable writes) · audit gaps across tiers · model/threshold version not recorded with decisions · replay impossibility (nondeterminism creep) · clock chaos breaking event ordering.
- **Harm:** incident unreviewable → no learning, no accountability, weakened legal/regulatory position; silently blocks the D20 miss-surrogate machinery. **Severity: S2 direct, S3 systemic** (it disables the safety-improvement loop).
- **Probability:** Med untreated (basis: durability bugs are common; determinism erodes without gates).
- **Detectability:** poor at occurrence (absence of data is quiet), good via drills that check the audit trail end-to-end.
- **Initial risk:** **Medium.**
- **Observable in production? — NO** (an evidence gap is discovered only when evidence is sought → drills + audit-completeness checks must manufacture the signal).
- **Subsystems:** Response & Escalation (journal), Delivery & Coordination (audit), Governance (versions). **Doctrine:** D11, D20; ADR-008/009. **SRS:** 302, 501, 904, 1005.
- **Academy lineage:** C2/C3 (durable journal, tamper), C12 (threshold governance needs change audit), B12 (replay determinism).

## H-09 — Privacy breach
- **UCA class:** data hazard (ISO 14971 harm includes privacy harm for a health product).
- **Failure modes / causes:** cloud breach exposing health/location plaintext (if minimization/E2E not enforced) · over-retention creating a breachable history · location in URLs/logs · gait/biometric template exfiltration · insider or acquirer misuse (the Life360 pattern) · FL update leakage (gradient inversion — C13) if federation ships naive.
- **Harm:** exposure of the most intimate data a person emits (health, location, routine, biometrics); for a safety brand, existential trust collapse. **Severity: S3** (per-person harm) **/ S4** (product-existential).
- **Probability:** Med untreated (basis: industry breach base rates); Low with the architectural stack.
- **Detectability:** poor (breaches are discovered late) → prevention-heavy control mix.
- **Initial risk:** **High.**
- **Observable in production? — NO** (requires pen tests, data-flow audits, breach drills — manufactured evidence again).
- **Subsystems:** Privacy/Trust Plane (owner), Delivery & Coordination (data at rest), all tiers. **Doctrine:** D05, D21. **SRS:** 105, 801, 802, 803, 804.
- **Academy lineage:** C13 (trust-minimization, FL leakage), B11 (keys/E2E/threat model), B6 (location retention), Ch 1.1 §11 (motion as biometric), Life360 Historian case.

---

## Ranked register (initial risk, pre-controls)

| Rank | Hazard | Initial risk | Observable? |
|---|---|---|---|
| 1 | H-01 Missed emergency | **Critical** | **No** |
| 2 | H-04 Silent coverage loss | **Critical** | Partially |
| 3 | H-02 False emergency | High | Yes |
| 4 | H-03 Delayed response | High | Yes |
| 5 | H-09 Privacy breach | High | **No** |
| 6 | H-05 Location unavailable/wrong | High | Partially |
| 7 | H-06 Duplicate escalation | Medium | Yes |
| 8 | H-08 Loss of evidence | Medium | **No** |
| 9 | H-07 Wrong recipient | Medium | Partially |

**The observability pattern is the headline:** the two worst hazards (H-01, H-04) and two others (H-08, H-09) are *not naturally observable in production* — exactly the class D20 warned about. Every `No`/`Partially` row therefore carries mandatory manufactured-evidence controls (drills, replay, shadow, audits) in [10B](10B-RISK-CONTROL-MATRIX.md); a `No`-observable hazard without a manufactured-evidence control is a release blocker.

*Probabilities are pre-deployment estimates (stated basis each). First shadow-mode field data re-scores this register — that re-scoring is itself a scheduled V&V activity (13).*
