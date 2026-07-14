# Chapter B10 — Backend: Alert Delivery, Push, Telephony & Live Location

> **Paired with:** Competency 11 (Anomaly Detection). The entire curriculum — nine sensors, fusion, HAR, baselines, anomaly detection — has been building toward a single moment this chapter finally delivers: **a decision becoming an alert a human receives.** Everything before was *deciding*; this is *delivering*. And it is where RAXHA's actual moat lives — not detection (the platforms commoditize that) but the **response layer**: getting the right people the right information reliably, at 3 a.m., when the network is flaky and someone's life depends on it. The backend is deliberately boring, and boring is the achievement.

---

## 1. Why the backend is the moat, not the detector

Detection gets commoditized (Apple/Google absorb it into the OS). What they *don't* build — and what families actually pay for — is the **response network**: multi-contact escalation, acknowledgment loops, live location for responders, cross-platform coverage, the "someone will know" guarantee. This is operationally heavy (24/7 SLA, telephony, per-country emergency plumbing), which is exactly why it's defensible: it can't be cloned by a feature team in a quarter. The backend is where "RAXHA helps when you can't" is kept or broken.

**The backend's prime directive:** an alert is not "sent" until a human has *acknowledged* it. Everything is engineered around that guarantee.

---

## 2. Reference architecture

```
 On-device Risk/Policy (decides SOS)
        │  authenticated event (idempotent EventEnvelope — B1/B7)
        ▼
 INGEST endpoint ──▶ durable queue (the alert is now safe even if everything downstream is down)
        │
        ▼
 ESCALATION ORCHESTRATOR  (server-side FSM mirror — the dead-man's switch, Decision #11)
        │
        ├──▶ DELIVERY LADDER (per contact, in order):
        │        push (APNs/FCM) ──timeout──▶ SMS ──timeout──▶ automated voice call
        │        each rung: delivery receipt + acknowledgment tracking
        │
        ├──▶ LIVE LOCATION RELAY (short-lived, token-scoped, expiring — B6)
        │
        └──▶ AUDIT LOG (every transition, immutable, for trust + postmortem)
        │
        ▼
 ACKNOWLEDGED (a human confirmed) ──or──▶ ESCALATE (next contact / emergency services)
```

**Stack (from Doctrine §4):** PostgreSQL (system of record — incidents, contacts, delivery receipts), Redis (queues/locks/rate-limits), an event queue, push service, object storage; Supabase Auth/Realtime/Edge Functions as *components*; later Kafka (event backbone) and **Temporal** (durable escalation orchestration — a natural fit for the long-running, retry-heavy, human-in-the-loop escalation FSM).

---

## 3. The delivery ladder — where reliability is won

Each contact is escalated through rungs, each rung with a timeout and a fallthrough:
- **Push (APNs / FCM):** fast, rich, free — but *not guaranteed* (device off, no network, budgets). A push is an *attempt*, never a delivery.
- **SMS (Twilio-class):** near-universal, high-reach, carries a link — the reliable middle rung. Delivery receipts matter.
- **Automated voice call (telephony):** the loudest, hardest-to-miss rung — a ringing phone at 3 a.m. wakes people a silent notification won't. Text-to-speech the incident + location.
- **Critical alerts** (iOS `critical-alert` entitlement; Android full-screen intents) pierce silent/DND — the responder-side must be provisioned for these.

**Rules:**
- **Acknowledgment-driven, not fire-and-forget:** advance the ladder until a human acknowledges; unacknowledged → next rung → next contact → (policy) emergency services.
- **Parallel + sequential:** notify the primary contact, and if unacknowledged within the timeout, fan out — don't serialize so slowly that help is late.
- **Multi-vendor failover:** the voice/SMS vendor is a single point of failure → secondary provider (an SRE non-negotiable for a safety system).
- **Idempotency end-to-end:** the `EventEnvelope` ID dedupes across retries so a flaky network can't send five terrifying duplicate alerts (the reused idempotency from Competency 2 / B7).

---

## 4. The dead-man's switch (Decision #11, server-side)

The escalation orchestrator is the *server-side mirror* of the on-device FSM. Its most important job is the failure case: **if the device was mid-incident and its heartbeat vanishes, the cloud escalates anyway.** This is what makes "no single device is the sole source of truth" real — the phone rebooting, dying, or losing signal mid-incident does not abandon the emergency, because the cloud is independently tracking it and will act on silence. Timers are durable (Temporal/scheduled jobs, not in-memory); the FSM survives server restarts; every transition is write-ahead logged.

---

## 5. Live location relay (privacy-critical)

From B6, enforced server-side: responders get location via a **short-lived, token-scoped, revocable** channel that **expires when the incident closes** — never a permanent URL, never location in a query string, updated live as the fix improves (with its uncertainty — Decision #15, "near home, medium confidence"). Retention is incident-only; no movement database (the Life360 architectural lesson). This is where privacy doctrine meets the wire.

---

## 6. Latency, reliability, security, failure

- **SLOs (measure these or you don't have a safety product):** trigger→first-notification p99 (seconds), delivery success rate per rung, acknowledgment rate/time, and **end-to-end drill success** (synthetic test incidents injected fleet-wide daily — the safety equivalent of a fire drill; if the drill doesn't fire, you'd never know the pipeline broke until a real emergency).
- **Reliability:** at-least-once + idempotent consumers (Doctrine #6); durable queue survives downstream outages; multi-vendor telephony; the alert is persisted before any processing.
- **Security:** authenticated ingest (only the user's device can create their incidents); contacts/PII encrypted at rest; least-privilege; the responder payload (Medical ID) fetched at send-time from protected storage, never in transit longer than needed. Never trust event content to route to endpoints (system doctrine — no injection-directed delivery).
- **Failure modes:**

| Failure | Cause | Defense |
|---|---|---|
| Alert lost when downstream is down | Processed before persisting | Persist to durable queue *first*, then process |
| Family terrified by 5 duplicate alerts | Retries without idempotency | EventEnvelope ID dedup end-to-end |
| Push sent, nobody saw it | Fire-and-forget push | Delivery ladder + acknowledgment + fallthrough |
| Nobody alerted; device died mid-incident | Relied on device to send | Server-side dead-man's switch (Decision #11) |
| Voice vendor outage = no alerts | Single telephony provider | Multi-vendor failover |
| Location link leaks / persists | Permanent URL / long TTL | Expiring token-scoped shares; incident-only retention |
| Pipeline silently broken | No synthetic testing | Daily fleet drills + SLO alerting |
| Alert storm from a bad model | Unbounded escalation | Rate limits, circuit breakers, canary (B8/B9) upstream |

---

## 7. RAXHA production shape

- **Ingest:** authenticated Edge Function / API → validate `EventEnvelope` → write to durable queue → ack device.
- **Orchestrator:** durable-workflow (Temporal-style) escalation FSM per incident; owns timers, ladder, fan-out, dead-man's switch.
- **Delivery adapters:** `PushSender` (APNs/FCM), `SmsSender` + `VoiceSender` (multi-vendor behind an interface), each returning delivery receipts.
- **`LocationShareService`:** mints expiring token-scoped share links; enforces incident-only retention.
- **Contact/consent model:** contacts opt in (they're being volunteered as responders — consent + notification-preference is a product and legal requirement); escalation policy is data (Doctrine — policy is configuration, changeable without a release).
- **Audit log:** immutable, every transition — for trust, debugging, and postmortems.
- **Observability:** SLO dashboards, delivery funnels, drill results, coverage telemetry (B1) — the fleet is the instrument.

---

## 8. Founder Intelligence

**Strategic reading:** THIS is the moat. Life360 proved families pay for a response network (~$1B+ scale) — and its worst wound (data-broker scandal) was in this layer's *privacy*, which RAXHA turns into a differentiator by architecture (incident-only retention, no movement DB). Detection is table-stakes and commoditized; the *reliable, private, cross-platform response network* is what RAXHA owns. **Why incumbents underbuild it:** it's operationally heavy (24/7, telephony, per-country) and doesn't sell hardware — structurally unattractive to Apple/Google, structurally perfect for a focused company. **The defensibility:** operational excellence (drill-tested reliability, multi-vendor, SLA) can't be cloned quickly, and it compounds with trust (a safety brand's reliability record is its moat). **Ledger:** ✅ push/SMS/voice infra, Temporal, the Life360 model; 🟡 optimal escalation policy (empirical); 🔴 competitors' delivery SLOs. **Kill-relevant:** if trigger→ack p99 or delivery success can't meet the safety bar under load, no amount of detection quality matters — the promise breaks at delivery. Fix delivery before growing.

## 9. Design Review (highlights)

- **SRE:** "Multi-vendor telephony failover, durable queue before processing, daily synthetic drills. Show me the pipeline survives a vendor outage and a downstream DB outage without losing an alert."
- **Privacy advocate:** "Location relay expiring + incident-only retention + no movement DB — in the schema. And contacts consented, not just entered by the user."
- **Emergency physician:** "The responder payload (allergies, meds, contacts) is the most valuable 10 seconds for my team. Available at send-time, on a locked/rebooted phone (Competency 2/3), accurate."
- **Investor:** "This is the moat, not the sensor. Reliability + privacy + cross-platform response. Prove the drill success rate and the delivery SLOs — that's the product."
- **Legal:** "Automated emergency-services contact is per-country regulated. Scope it; default to family; know the law before dialing 911/112 automatically."

## 10. Constraint Exercise

Design RAXHA's alert-delivery backend for launch: 10k users, trigger→first-notification p99 < 5s, zero lost alerts, no duplicate alerts, multi-contact escalation with acknowledgment, live location that expires, incident-only retention, and a daily synthetic drill. Constraints: 2 engineers, modest infra (Doctrine §4 stack), and the dead-man's switch must fire if a device dies mid-incident. Specify: the ingest→queue→orchestrator→ladder flow, idempotency, the dead-man's-switch mechanism, multi-vendor failover, the location-sharing + retention design, and the SLOs/drills you instrument. One-page memo.

## 11. Chief Scientist's Verdict

**Confidence Ledger:** Durable-queue + idempotent + at-least-once delivery — ★★★★★ (proven distributed-systems practice). Delivery ladder (push→SMS→voice) with acknowledgment — ★★★★★. Server-side dead-man's switch — ★★★★★ (Decision #11 realized). Expiring token-scoped location sharing — ★★★★☆ (sound; needs enforcement). "Response layer is the moat" — ★★★★☆ (strong strategic argument; Life360 evidence).
**TRL:** Push/SMS/voice delivery infra — 9. Durable escalation orchestration (Temporal) — 9. Daily synthetic safety drills — 7–8 (standard SRE, needs building). Multi-vendor telephony failover — 8. Cross-platform private response network — 6–7 (RAXHA's integration build).
**Roadmap:** *MVP:* ingest→durable queue→orchestrator→push+SMS ladder→ack→dead-man's switch→expiring location→audit log→daily drill. *V2:* voice rung, multi-vendor failover, Temporal orchestration, critical-alerts. *V3:* regulated emergency-services integration (per-country). *Never Build:* fire-and-forget alerts; single-vendor telephony; permanent location URLs; server-side movement DB; processing before persisting.
**Competitor failures (sourced):** Life360 location-broker scandal (the response-layer privacy failure to architect against). Documented medical-alert-service complaints centering on false alarms + monthly fees, not detection — the response *experience* is where incumbents bleed. Push-notification unreliability (widely documented) — why safety never rests on push alone. Emergency-alert-system false-alarm incidents (e.g., false public alerts) — the reputational cost of a delivery-layer failure is enormous; drills and idempotency are the defense.
**Kill Criteria:** if trigger→ack p99 or delivery success can't meet the safety bar under load, halt growth and fix delivery (a broken promise scales negatively). If non-monetized/incident-only location retention can't be architecturally guaranteed, don't market privacy. If automated emergency-services dialing can't be made legally compliant per market, default to family-only and say so.
**Historical Failures (Historian):** Life360 (the canonical response-layer case). Public emergency-alert false alarms (documented — e.g., false missile/amber alerts) — delivery-layer errors erode the trust the whole system runs on; RAXHA treats delivery with the seriousness of the detection it delivers. Medical-alert pendant services' churn from false-alarm fatigue — the response experience, not the sensor, drove abandonment.

## 12. Knowledge Graph Connections

- **Depends on (prior):** B1 (four-tier architecture, escalation FSM, data plane), B6 (expiring location sharing), B7 (idempotent EventEnvelope, watch autonomy), Competency 2 (durable FSM), C11/C12 (the decision it delivers), Decisions #6 (delivery contract), #11 (dead-man's switch), #15 (responder vocabulary).
- **Depended on by (future):** the Emergency Decision + Response layer (the top of the stack); regulatory/clinical validation (Module 16) of the end-to-end promise.
- **RAXHA subsystem:** the Response layer — RAXHA's moat; turns a decision into a delivered, acknowledged alert.
- **AI models consuming it:** none (delivery infrastructure) — but it delivers the output of the entire model stack.
- **Sensors contributing:** none directly — carries the whole system's conclusion to humans.
- **Assumptions for validity:** persist-before-process; idempotent; at-least-once; acknowledgment-driven; multi-vendor; dead-man's switch independent of the device; location expires; drills run.
- **Confidence:** delivery infra ★★★★★ / cross-platform private response network ★★★★. See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Competency 12 pairing: **Context Awareness & Risk Scoring → the Emergency Decision** (Module 12 / the Decision Engine) + **B11 — Security engineering: Keychain/Keystore, E2E encryption, TEE**. The stack has a calibrated human-state estimate and anomaly candidates; next is where they become a *risk score* and a *policy decision* — the last inference layer before the alert this chapter delivers.*
