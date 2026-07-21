# A1–A4 Filing Pack (drafted 2026-07-21, under founder delegation)

> Claude cannot file these — each requires the founder's Apple developer account, business identity, counsel engagement, or email signature. Everything below is drafted so each action is **≤15 minutes of founder time**. All four are calendar clocks: lead time starts only when filed.

---

## A1 — Apple entitlement requests (file BOTH today)

**Where:** Apple Developer account → the fall-detection entitlement request form linked from the [CMFallDetectionManager docs](https://developer.apple.com/documentation/coremotion/cmfalldetectionmanager), and the Critical Alerts request form (developer.apple.com/contact — "Critical Alerts entitlement"). Community-reported turnaround: fall detection ~2–3 days; critical alerts days–weeks.

**Draft justification (fall detection — paste and adapt):**
> RAXHA is a personal-safety application for older adults living alone. It uses `CMFallDetectionManager` to receive fall events *after* Apple's native fall-detection UI and SOS flow complete, in order to coordinate notification of the user's chosen family contacts with the event's resolution state. The app never suppresses or replaces the system flow; it acts strictly downstream of it. Detection decisions are deterministic on-device logic — no server round-trip gates any alert.

**Draft justification (critical alerts):**
> RAXHA delivers family-notification alerts for suspected medical emergencies (falls, unresponsiveness) affecting an elderly user. Alerts must be audible to designated family responders even under Do Not Disturb / Focus / silent switch, matching Apple's approved personal-safety and SOS use-case category. Volume is strictly limited to genuine emergency escalations; routine notifications use standard channels.

**Record in the Evidence Register when filed:** filing date → E-02/E-03 get actual turnaround data.

---

## A2 — Deliverability registrations (SMS + voice)

Checklist (any CPaaS vendor — Twilio/Telnyx-class; single-vendor is accepted debt TD-3):
1. Register the **brand** (legal entity, EIN/company number) for A2P 10DLC.
2. Register a **campaign**: use-case "emergency notification / account alert"; sample messages = the ladder's SMS rungs (include opt-in language: contacts consented in-app during enrollment).
3. **Branded/verified calling**: enroll the outbound number for STIR/SHAKEN attestation A + a CNAM display name ("RAXHA ALERT") so 3 a.m. calls don't show "Scam Likely."
4. Buy one dedicated long code for alerts; never mix marketing traffic onto it.
5. When registrations clear → SPIKE-007 deliverability matrix becomes runnable.

---

## A3 — Liability counsel brief (one page to hand a lawyer)

**Engagement scope:** product-liability posture for a consumer personal-emergency-detection app (NOT a medical device; no diagnostic claims — see PDR-005/D22 claims boundary).
1. E&O / product-liability insurance suitable for a safety-adjacent consumer app, pre-beta.
2. ToS + disclaimer architecture: "aid to awareness, not a guarantee of rescue"; no medical claims; the claims-language boundary audited by VV-801.
3. Beta consent framework for elderly participants (capacity, guardian co-consent where applicable) — intersects RFC-007's reserved elder-agency question; counsel input feeds that founder decision.
4. Data protection: incident-time location sharing, minimization commitments (D21), India VPC posture.
5. Jurisdiction: initial market = India (founder-attested legal all-clear for predecessor continuity; verify transfer).

---

## A4 — FARSEEING consortium request (email draft — send from founder address)

**To:** FARSEEING consortium data-access contact (via [the meta-database paper](https://link.springer.com/article/10.1186/s11556-016-0168-9) corresponding author / listed contact).
**Subject:** Data-access request — real-world fall signals for elderly-safety validation research

> Dear FARSEEING consortium,
>
> I am the founder of RAXHA, a personal-safety system for older adults living alone, which detects falls and other emergencies from wrist-worn sensors and alerts family responders. We maintain a deterministic replay-validation corpus and are seeking ground-truth data of real-world falls in older adults — which, to our knowledge, only the FARSEEING repository provides at meaningful scale (208 verified real-world falls).
>
> We request access to the fall-signal recordings (accelerometer/gyroscope time series with fall annotations) under your data-sharing terms. Intended use: offline validation of detection thresholds and false-negative analysis for an elderly population; data would not be redistributed, and we will follow your citation and usage requirements. We are open to a formal research-collaboration agreement if that is the preferred route.
>
> Could you share the access procedure and terms?
>
> Regards, Vinay [surname], Founder, RAXHA — [contact details]

**On reply:** record lead time + terms in E-20; corpus ingestion becomes a SPIKE-010 work item with per-source provenance (the corpus already supports `provenance` blocks).
