# RAXHA Product Specification v1.0 (PRD)

> **Phase-2 artifact #0.** *What RAXHA v1 is* — the PRD answers "what"; the Master Architecture Blueprint (08) answers "how." Written around the v1 beachhead: **independent older adults living alone, with family caregivers as the response network.** Status: DRAFT for review. Read the one-page **[RAXHA-NORTH-STAR.md](../00-foundation/RAXHA-NORTH-STAR.md)** first — it is the product intent this PRD expands. Every claim here stays inside **Decision #22 — RAXHA detects, monitors, assesses risk, and notifies; it never diagnoses, treats, prescribes, or provides medical advice.** Pricing/packaging are *product truth* (Decision #12 — revisable).

---

## 1. One-sentence product

**RAXHA v1 is a family-facing safety service for an older adult living alone: it automatically detects a probable fall or emergency on the watch they already wear, and — when they cannot ask for help themselves — reliably alerts their family with location and context, while continuously assuring the family that protection is actually on.**

It does **not** diagnose, monitor a medical condition, prevent falls, or replace clinicians or 911. It ensures the right people know *sooner*.

**Platform-independence principle (load-bearing — Decisions #2, #17):** *RAXHA integrates with platform detection capabilities where available, while maintaining an independent risk-assessment and response engine. Platform detections are treated as evidence inputs, not authoritative decisions.* If Apple's detection improves, RAXHA uses it; if Apple changes an API, removes a feature, or Android differs, RAXHA still has its own engine. The core asset is RAXHA's deterministic risk engine + response layer — never a wrapper around someone else's detector.

## 2. The customer (three roles, one buying unit)

- **The Wearer — "Margaret," 78, lives alone.** Mild frailty, some fall risk, values independence, dislikes anything that looks "medical" or makes her feel monitored. Will tolerate a normal smartwatch; would abandon a stigmatizing pendant (Decision #14 — the pendant non-wear failure is the thing we exist to beat). Low tech tolerance: her side must be nearly invisible.
- **The Monitor/Buyer — "David," 48, her son.** Anxious about "what if she falls and I don't know for hours." Sets everything up, receives alerts, wants *peace of mind* and *proof it's working*. **He is who we sell to and who churns.**
- **The Payer.** v1 default: **David pays** (family consumer subscription). Parallel pilot: **elder-care agencies/facilities** pay per resident (the B2B / reimbursement path, larger long-term — Competency 15).

## 3. Problem (why now, why today fails)

When an older adult living alone falls or collapses, they frequently **cannot summon help** — phone out of reach, unconscious, confused, or on the floor for hours. Today's options fail specifically:
- **Medical pendants:** stigma → **non-wear** → zero protection (documented; Ch 1.1 Historian).
- **Apple/Samsung fall detection:** genuinely good *detection*, but a **thin family-response layer** — it calls emergency services or a single contact; it does not give the *family* a coordinated, acknowledged, "is Mom protected right now" experience, cross-contact escalation, or coverage assurance.
- The gap RAXHA fills is **not *just* better detection** — it is an **independent risk engine that fuses every available signal (including platform detections as inputs) PLUS the response network + coverage assurance + an elder-invisible experience.** Detection alone is increasingly commoditized by the platforms; the defensible, ownable layer is RAXHA's own assessment-and-response engine (the moat identified across the curriculum: B1, B10, C15).

## 4. Scope — IN (v1)

1. **Automatic fall detection via RAXHA's own risk engine** — which *ingests* platform detections (Apple Watch `CMFallDetectionManager`) as high-value **evidence inputs**, fuses them with its own signals/context, and makes the escalation decision itself (Decisions #2/#17). Platform signal is an input, not the verdict; RAXHA owns confirmation, context, and response (B1, B2, B4).
2. **Prolonged-inactivity / no-movement signal** as corroborating context (not a standalone medical claim).
3. **Manual SOS** (watch button + phone).
4. **Elder-friendly countdown + cancel** — large target, loud escalating alarm, strong haptics; the studied Apple pattern (C12 §3.5). Unresponsive → escalate.
5. **Family alert with live location + context** — "a hard fall was detected and Margaret hasn't responded," last-known location with honest uncertainty (Decision #15), map, live updates.
6. **Delivery ladder + acknowledgment** — push → SMS → automated voice call, per contact, in order, until a human acknowledges; then escalate to the next contact (B10, Decision #6).
7. **Coverage Assurance** (the differentiator) — the family sees, at a glance, *is she protected right now*: watch worn, charged, phone reachable, pipeline alive, % of day protected (Doctrine #9; Decision #14/#20).
8. **Non-wear coaching** — gentle nudges to wearer/family before an emergency, not after (Decision #14).
9. **Responder info card** — allergies, medications, emergency contacts, entered by family, shared with responders at incident time as *information* (not diagnosis; Decision #22), available on a locked/rebooted phone (Competency 2/3) and expiring after the incident (Decision #21).
10. **Privacy by architecture** — on-device processing, event-not-waveform, incident-only location retention, no data sale (Decisions #5, #21, #22).

## 5. Scope — OUT (explicitly NOT solved in v1 — the boundary that keeps us honest)

- ❌ **No diagnosis, medical advice, treatment, or condition-monitoring** (Decision #22). We never say "your heart," "you have," "you should take."
- ❌ **No cardiac/AFib/seizure detection claims** — no clearance, and outside the beachhead; possibly *screening* integration far later, only if validated (C15).
- ❌ **No fall *prediction*/"prevention"** — v1 is fall *detection + response*. Fall-risk *awareness* is a validated V2+ feature (C8, C14 — needs V3).
- ❌ **No automatic 911/emergency-services dialing by RAXHA** — per-country regulated (C15); v1 defaults to **family-first**. (The watch's own native emergency SOS remains available to the user as a platform feature.)
- ❌ **No room-level indoor location** — v1 uses GPS + the registered **home address** as the honest indoor answer (C6/C7); room-level needs infrastructure (facility tier, later).
- ❌ **No Android/Wear OS in v1.0** — Apple Watch + iPhone first (best detection, one reliable platform). **Wear OS is v1.1**, not v2 — cross-platform is the long-term moat, just not the first release.
- ❌ **No standalone hardware** — RAXHA rides the watch the customer already owns/buys.

*Naming what we don't do is a feature: it's how the family trusts what we DO claim (Decision #22, C15 claims discipline).*

## 6. Success metrics (North Star + guardrails)

- **North Star:** *true emergencies where the family was informed in time to act.*
- **Coverage KPI (leading, pre-any-fall):** median % of day a wearer is actually protected (worn + charged + pipeline alive). This is the product's health before any incident (Doctrine #9).
- **Detection quality:** shadow-validated real-world catch rate; **false alarms per wearer-week** (Decision #19) and an **estimated-miss surrogate** watched *together* (Decision #20).
- **Response:** trigger → family-acknowledged **p99 latency**; delivery success per rung (B10).
- **Trust/retention:** non-wear rate, family app engagement, subscription churn. (Churn is the business — B1/B10.)

## 7. Product surfaces (screens)

**Wearer side (kept nearly invisible):**
- *Watch:* a calm status ("Protected"); a prominent **SOS**; during an incident, a full-screen **countdown with a large Cancel** + loud/haptic alarm; a low-friction **"Are you OK?"** check (for low-confidence + alarming context — Decision #13).
- *Phone (wearer):* set-up-once, then near-silent; battery/worn reminders only.

**Family side (the real product — "David's app"):**
- **Home:** one status card per monitored elder — **Protected / Degraded / Alerting** — with coverage ("worn · charged · protected 7h today").
- **Incident (live):** what happened, location map with **uncertainty shown honestly**, **Acknowledge**, **Call Margaret**, escalation status ("notifying your sister…").
- **History:** past incidents and false alarms, resolutions.
- **Coverage & device health:** battery, worn/off, gaps, nudge controls.
- **Setup:** contacts + escalation order, quiet hours, wearer profile + responder info card, permissions status.

## 8. Key user journeys

1. **Onboarding (family-led):** David sets up Margaret's watch, grants permissions rationale-first (B6/B4/B2), adds himself + sister with escalation order, enters the responder info card. Outcome: "Margaret is Protected."
2. **Normal day:** Margaret wears the watch; David sees "Protected, 8h today." Forgets to put it on → gentle nudge to both.
3. **Real fall (the moment we exist for):** fall detected → countdown → Margaret unresponsive → RAXHA alerts David: *"Hard fall detected, no response, at home, 12s ago."* → David acknowledges, calls her, or the ladder escalates to his sister, then (policy) onward. Live location; incident stays open until resolved.
4. **False alarm:** Margaret sits down hard → countdown → she taps **Cancel** → no alert; logged for shadow labeling (Decision #20).
5. **Non-wear gap:** watch on charger all afternoon → David sees "Degraded — not worn since 1pm," one-tap reminder.
6. **Phone dies mid-incident:** dead-man's switch escalates server-side regardless (Decision #11) — the incident is never abandoned.

## 9. Onboarding & permissions

Staged, rationale-first, safety-framed (B2/B3/B6): HealthKit (fall events + HR context), Core Motion, Location (**Always**, escalated with a clear "so we can tell your family *where* you are in an emergency"), Notifications (**critical alerts** for the family responders so alarms pierce silent/DND — B2), Background. Each partial-consent state maps to an explicit, **honestly-labeled** protection level (never a silent gap — Decision #13/#20).

## 10. Notifications

- **Wearer:** countdown alarm (loud + haptic), "Are you OK?" check, wear/charge reminders. Minimal, never nagging.
- **Family:** incident alert (critical, pierces DND, with acknowledge), escalation-in-progress, **coverage warnings**, resolution/"she's OK." Idempotent — a flaky network never sends five terrifying duplicates (Decision #6, B10).

## 11. Failure UX & Recovery UX (safety-critical — the part normal apps skip)

**Failure UX (degrade honestly, never silently):**
- Low-confidence detection + alarming context → **"Are you OK?"** on the watch, not silence (Decision #13).
- No/poor location → family sees *"At home (last known) · GPS unavailable"* — honest, not a confident wrong pin (Decision #15).
- Network/phone down → SMS/voice fallback + dead-man's switch (Decision #11).
- Non-wear / low battery → surfaced as **Degraded**, with a fix, never hidden (Decision #14/#20).

**Recovery UX:**
- After a real alert: family resolution flow ("She's OK" / "Help is on the way") → incident closes → **live-location sharing expires** (Decision #21).
- After a false alarm: one-tap "That wasn't real" → feeds shadow labels (Decision #20).
- After a coverage gap: nudge + one-tap re-arm.

## 12. Business model (product truth — revisable, Decision #12)

- **v1 default:** family-pays consumer **subscription** (monthly, per monitored elder). Freemium: basic detection + one-contact alert free; **premium** = multi-contact escalation, automated voice calls, coverage history, responder card, priority delivery. Rationale: fastest path to real users + the shadow-data flywheel (C9/C13).
- **Parallel:** elder-care **agency/facility pilots** (per-resident licensing) — the B2B + reimbursement path that is the larger long-term prize (C15, Dexcom model).
- *Pricing numbers are deliberately left to a pricing study — flagged as product truth, not doctrine.*

## 13. Edge cases (v1 must have an answer for each)

- **No iPhone (LTE watch only)** → **out of scope for v1** (v1 requires iPhone + Apple Watch — see §14). The watch-autonomous SOS path is a v1.1+ feature; the no-iPhone elder segment waits.
- **Multiple elders per family monitor** → multi-card home.
- **Night / sleep** → wearer removes watch; coverage expectations configurable (don't cry "non-wear" at 3am if that's the agreed rule).
- **Atypical gait (e.g., Parkinsonian, post-stroke)** → personalization so we don't false-alarm on their normal (Decision #16) — *awareness*, never diagnosis (Decision #22).
- **Wrong wearer** (someone else dons the watch) → wearer-verification is V2 (C8); v1 assumes the enrolled wearer.
- **Traveling / away from home** → location context adapts; home-address fallback is home-only.

## 14. Platform & delivery constraints

**v1 requires iPhone + Apple Watch** (resolved 2026-07-14 — smaller device matrix, tighter QA, fastest launch, strongest ecosystem knowledge). Native (Swift/SwiftUI, B2); platform fall events are **evidence inputs to RAXHA's own risk engine** (not the decision); RAXHA owns the risk engine + response layer + family app + backend (B1, B10). Cloud = coordination + delivery + dead-man's switch, **never gates the SOS** (Decision #2). Wear OS = **v1.1**; LTE-watch-standalone = v1.1+.

## 15. Boundary statement (Decision #22 — the exact claims we make)

RAXHA v1 **detects** probable falls/emergencies, **notifies** family, **shares** location + responder info, **assures** coverage, and **encourages** professional help when appropriate. RAXHA v1 does **not** diagnose, treat, prescribe, advise medically, monitor a medical condition, or prevent falls. Marketing, UX copy, and app-store claims are bound to this statement.

**The advertisable coverage promise (resolved 2026-07-14 — the ONLY coverage claim we make):** *"RAXHA continuously monitors for meaningful safety events and, when confidence is sufficient, coordinates timely notification of the user's chosen contacts."* We do **not** promise "we will always detect emergencies" — that claim is unmeasurable, undefendable, and violates Decisions #16/#19/#20. Every coverage-related string in the product inherits this wording.

## 16. Product decisions (resolved 2026-07-14)

1. **Pricing** — **intentionally deferred.** Requires user interviews before any number is set; do not pre-commit tiers. (Family subscription + facility per-resident are the two models to test.)
2. **v1 escalation default** — **family-only.** No emergency-services dialing by RAXHA in v1 (regulatory per market, C15); the watch's own native 911 SOS remains available to the user.
3. **Coverage promise** — **resolved** to the exact wording in §15 (monitors for meaningful events; notifies when confidence is sufficient). Never "always detect."
4. **Device requirement** — **iPhone + Apple Watch required for v1.** LTE-watch-standalone and Android/Wear OS are v1.1+.

*(Only #1 remains genuinely open, and by design — it is gated on user research, not on engineering.)*

## 17. Traceability (this PRD → doctrine/competencies)

Beachhead & non-wear focus → Decision #14, Ch 1.1 Historian. Detection-rides-platform, moat-is-response → B1/B2/B10, C15. Boundary/claims → Decision #22, C15. Coverage KPI → Doctrine #9, Decision #20. Honest degradation & uncertainty → Decisions #13/#15. Privacy → Decisions #5/#21. Reboot/dead-man → Decision #11, Competency 2/3. Every requirement in the forthcoming SRS traces back through this PRD (the §5 traceability spine of 06-PHASE-2-TRANSITION).

---

*Next in sequence (06 playbook): **08-MASTER-ARCHITECTURE-BLUEPRINT.md** — how this product is built (the ten diagrams, trust/failure/latency boundaries, the five-risks answer). The PRD defines the "what"; the Blueprint answers the "how."*
