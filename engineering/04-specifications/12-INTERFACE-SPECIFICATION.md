# 12 — Interface Specification

> **Every interface, not only HTTP.** Four categories: **Internal** (subsystem↔subsystem), **Platform** (OS APIs we consume, not own), **Network** (device↔cloud↔responder↔vendors), **Human** (wearer/family interactions — they are interfaces too). **Contract-first, transport-second:** an interface is defined by *producer, consumer, contract, failure semantics* — transport bindings appear only in Part B and are swappable implementation. Contracts use **only** the frozen vocabulary/objects of [08B](../02-architecture/08B-DATA-DICTIONARY.md); producers/consumers are the frozen subsystems of [08A](../02-architecture/08A-SUBSYSTEM-RESPONSIBILITY-MATRIX.md).
>
> **Failure-semantics taxonomy (honest):**
> - `best-effort` — may be lost; loss must be *detectable* (gap/staleness), never silent.
> - `at-least-once` — retried until acknowledged; duplicates possible in transport.
> - `exactly-once-effect` — at-least-once transport **+ idempotent consumer** (dedup by ID). *True exactly-once transport does not exist in distributed systems (D06); claiming it would be a lie — the effect, not the transport, is exactly-once.*
> - `latest-value` — a state, not a queue: consumers read the newest value + its staleness; intermediate values may be skipped by design.
>
> **Contract versioning:** every contract is versioned (`HumanState v1`, …). Additive optional fields = non-breaking. Any breaking change = **new version + RFC** — a contract change is architecture, not implementation (00A discipline). Producers state the version in every message.

---

## §1 Internal Interfaces (on-device, subsystem → subsystem)

| ID | Interface | Producer → Consumer | Contract | Semantics | Notes / SRS |
|---|---|---|---|---|---|
| IF-INT-01 | **Evidence Published** | Sensing Layer → Human State Engine (+ Coverage Monitor) | `SensorEvidence v1` | `best-effort` stream **with explicit gap markers** | Loss is tolerated but never silent (D13); quality/staleness attached at source. SRS-101, 103, 104 |
| IF-INT-02 | **Human State Published** | Human State Engine → Risk Engine (+ Coverage context) | `HumanState v1` | `latest-value` (+ staleness) | One canonical estimate (ADR-006); consumers must check `at`/Confidence. SRS-201, 202 |
| IF-INT-03 | **Risk Assessment Published** | Risk Engine → Policy Engine | `RiskScore v1` | per-evaluation, deterministic | Same inputs ⇒ same output (ADR-008 reach-through); versions stamped. SRS-301, 302 |
| IF-INT-04 | **Policy Decision Issued** | Policy Engine → Response & Escalation | `PolicyDecision v1` | **`exactly-once-effect`** (idempotent by decision id) | The life-critical hand-off; duplicate issuance must not double-escalate. SRS-401, 503 |
| IF-INT-05 | **Incident Journal** | Response & Escalation ↔ durable store | `Incident v1` + `EscalationState v1` | write-ahead durable; reboot-recoverable | Persisted deadlines, boot-readable minimal journal (ADR-105). SRS-501, 502 |
| IF-INT-06 | **Coverage Published** | Coverage Monitor → family surface + Risk (context) | `DeviceCoverage v1` | `latest-value` | Cause-attributable degradation; never hidden (D09). SRS-701 |

## §2 Platform Interfaces (consumed, not owned — platform truth, D12: re-verify each OS release)

| ID | Interface | Platform ↔ RAXHA side | Mapped Contract | Semantics | Notes / SRS |
|---|---|---|---|---|---|
| IF-PLT-01 | **Platform fall/motion events** | CoreMotion / `CMFallDetectionManager` → Sensing adapter | → `SensorEvidence v1` (`source=platform_detection`) | `best-effort` (platform-scheduled) | Evidence, never authority (ADR-004); availability is entitlement-gated. SRS-102 |
| IF-PLT-02 | **Health store** | HealthKit ↔ adapter | → `SensorEvidence v1` (baselines/records) | store-sync, **not a live wire** | Background delivery is system-scheduled (B4/D07 rejection: never the emergency path). SRS-101 |
| IF-PLT-03 | **Location** | CoreLocation → Sensing adapter | → `SensorEvidence v1` (kind=location, uncertainty+age mandatory) | `best-effort` + pre-warm on suspicion | Accuracy is a probabilistic field (C6). SRS-104 |
| IF-PLT-04 | **Watch ↔ Phone link** | WatchConnectivity ↔ both apps | `EventEnvelope v1` | `at-least-once` (store-and-forward) → exactly-once-effect at consumer | Link down ≈10% of life; queue + dedup. SRS-503 |
| IF-PLT-05 | **Push wake/notify** | APNs ↔ apps | (carrier for `AlertEnvelope v1` refs) | `best-effort` | Push is an attempt, never the only rung (ADR-106). SRS-505 |

## §3 Network Interfaces (device ↔ cloud ↔ responders/vendors)

| ID | Interface | Producer → Consumer | Contract | Semantics | Notes / SRS |
|---|---|---|---|---|---|
| IF-NET-01 | **Incident event upload** | Phone (Response) → Delivery & Coordination ingest | `EventEnvelope v1` | **`exactly-once-effect`** (at-least-once + `eventId` dedup) | Persist-before-process on the cloud side. SRS-503, 601 |
| IF-NET-02 | **Heartbeat** | Device → Delivery & Coordination | heartbeat record (wearerId, at, incidentId?) | `best-effort` — **absence is the signal** | Feeds the dead-man's switch; heartbeat reliability is an SLO (Blueprint risk #4). SRS-602 |
| IF-NET-03 | **Alert dispatch** | Delivery & Coordination → push/SMS/voice vendors | `AlertEnvelope v1` | `at-least-once` per rung, receipt-tracked, ack-driven fallthrough | Multi-vendor failover (ADR-106). SRS-505, 604 |
| IF-NET-04 | **Acknowledgment** | Responder device → Delivery & Coordination | ack fields of `AlertEnvelope v1` | `at-least-once`, idempotent | Ack is the ladder's terminal event (D06). SRS-505 |
| IF-NET-05 | **Live location share** | Delivery & Coordination → responder view | `Incident.location` via expiring token | `best-effort` refresh; staleness always shown | Token-scoped, expires on resolution (D21/ADR-111). SRS-801 |
| IF-NET-06 | **Safety-config & model delivery** | Governance → devices | signed artifact (model/threshold + versions) | `exactly-once-effect` by version; **signature-verified before activation** | ADR-112; unsigned = rejected. SRS-803, 901 |

## §4 Human Interfaces (interactions are contracts too)

| ID | Interface | Between | Contract (what each side owes) | Failure semantics | Notes / SRS |
|---|---|---|---|---|---|
| IF-HUM-01 | **Countdown & cancel** | RAXHA ↔ wearer | Full-screen countdown, loud + haptic; one large cancel target | **No response ⇒ escalate** (timeout is the safe default); cancel = exactly-once-effect, logged as shadow label | Elder-accessible under stress (PRD §7). SRS-406 |
| IF-HUM-02 | **"Are you OK?" check-in** | RAXHA ↔ wearer | Low-friction prompt on low-confidence + alarming context | "OK" de-escalates; **no response ≠ OK** → continues evaluation/escalation (D13) | SRS-404 |
| IF-HUM-03 | **Manual SOS** | Wearer → RAXHA | One deliberate action → immediate `PolicyDecision(escalate)` | Must work offline; accidental-trigger guard without adding friction | PRD §4.3. SRS-1101 path |
| IF-HUM-04 | **Family alert & acknowledgment** | RAXHA ↔ responder | Critical alert (pierces DND) with context + location(+uncertainty/age) + one-tap Acknowledge | Unacked ⇒ ladder climbs; ack stops escalation for that incident (exactly-once-effect) | D15 responder vocabulary. SRS-505 |
| IF-HUM-05 | **Coverage surface & coaching** | RAXHA ↔ wearer + family | Protected/Degraded/Alerting with attributable cause; rate-limited nudges | Degradation must be *seen* (surfaced ≠ shipped-to-a-log); quiet hours respected | D09/D14. SRS-701–703 |

---

## Interface Dependency Matrix (the one-pager)

| Interface | Producer | Consumer | Contract (ver) | Failure semantics | SRS |
|---|---|---|---|---|---|
| IF-INT-01 Evidence | Sensing | HSE, Coverage | SensorEvidence v1 | best-effort + gap markers | 101–104 |
| IF-INT-02 State | HSE | Risk | HumanState v1 | latest-value | 201–202 |
| IF-INT-03 Risk | Risk | Policy | RiskScore v1 | deterministic per-eval | 301–302 |
| IF-INT-04 Decision | Policy | Response | PolicyDecision v1 | exactly-once-effect | 401, 503 |
| IF-INT-05 Journal | Response | store | Incident v1/EscalationState v1 | write-ahead durable | 501–502 |
| IF-INT-06 Coverage | Coverage | family, Risk | DeviceCoverage v1 | latest-value | 701 |
| IF-PLT-01 Platform events | OS | Sensing | SensorEvidence v1 | best-effort | 102 |
| IF-PLT-04 Watch link | watch | phone | EventEnvelope v1 | at-least-once → e-o-effect | 503 |
| IF-NET-01 Upload | phone | cloud | EventEnvelope v1 | exactly-once-effect | 503, 601 |
| IF-NET-02 Heartbeat | device | cloud | heartbeat | best-effort (absence = signal) | 602 |
| IF-NET-03 Dispatch | cloud | vendors | AlertEnvelope v1 | at-least-once + receipts | 505, 604 |
| IF-NET-04 Ack | responder | cloud | AlertEnvelope v1 (ack) | at-least-once idempotent | 505 |
| IF-NET-05 Location share | cloud | responder | Incident.location (token) | best-effort + staleness | 801 |
| IF-NET-06 Config/model | Governance | devices | signed artifact | e-o-effect by version | 803, 901 |
| IF-HUM-01 Countdown | RAXHA | wearer | countdown/cancel | timeout ⇒ escalate | 406 |
| IF-HUM-02 Check-in | RAXHA | wearer | prompt/response | no response ≠ OK | 404 |
| IF-HUM-03 Manual SOS | wearer | RAXHA | SOS action | offline-capable | 1101 |
| IF-HUM-04 Alert/Ack | RAXHA | responder | AlertEnvelope v1 | unacked ⇒ climb | 505 |
| IF-HUM-05 Coverage | RAXHA | wearer+family | DeviceCoverage v1 | must be seen | 701–703 |

**Chain into V&V (13):** every row above → its contract → its SRS → a `VV-` test (e.g., `RiskScore v1 → SRS-403 → VV-403`). An interface without a test, or a test without an interface/requirement, is a defect.

---

## Part B — Transport bindings (illustrative, swappable — NOT architecture)

`IF-NET-01` → HTTPS `POST /v1/events` (JSON, TLS+pinning) · `IF-NET-03` → APNs / SMS vendor API / TTS voice vendor API (behind a `DeliveryVendor` port, multi-vendor) · `IF-NET-05` → HTTPS short-lived tokened URL (no location in query strings — D21) · `IF-PLT-04` → WatchConnectivity `transferUserInfo` (queued) / `sendMessage` (live) · storage → SQLite (journal, WAL). Changing any binding here changes **no** row above — that is the test that §1–§4 captured architecture, not implementation.

---

**The standing question this document must satisfy:** *could a new engineer implement the system correctly using only this document and its upstream references (08A/08B/09/10B/11)?* If an implementation question arises that none of them answers, the gap is fixed **in the documents**, not in someone's head or a chat log.
