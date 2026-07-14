# PDR-000 — Product Decisions Register

> **Phase-2 foundational artifact — sits between the North Star (07) and ADR-000 (07B).** These are the **product/business decisions** that shape RAXHA v1 — deliberately kept *separate* from architecture decisions (ADR-000).
>
> **The distinction matters:** an **ADR** is an architecture constraint (stable; changing one is an architecture-review event). A **PDR** is a product/business decision — **"product truth" (Doctrine #12), and therefore revisable** as user research and the market teach us. Changing a PDR is a *product* decision informed by evidence; it should *not* force an architecture change (that's the whole point of separating them). A well-built architecture (ADR-000) survives every PDR flip below.
>
> **Traceability:** North Star → **PDR** → ADR → Blueprint → SRS. Format per entry: Decision · Rationale · Status · Revisit-when · Derives-from.

---

## PDR-001 — Beachhead customer
- **Decision:** Independent older adults living alone (wearer), with adult-child/family caregivers as the response network and economic buyer. B2B elder-care agencies are a parallel pilot, not the v1 focus.
- **Rationale:** clearest problem, real willingness-to-pay, strongest evidence base, a reimbursement path (Competency 15).
- **Status:** Accepted (v1). **Revisit-when:** the family-consumer motion underperforms vs the agency/B2B motion in early traction.
- **Derives from:** North Star; PRD §2; Ch 1.1 Historian (non-wear).

## PDR-002 — Apple ecosystem first
- **Decision:** v1 requires **iPhone + Apple Watch**.
- **Rationale:** smaller device matrix, tighter QA, fastest launch, strongest ecosystem knowledge, best platform detection to *ingest as evidence* (ADR-004).
- **Status:** Accepted (v1). **Revisit-when:** v1.1 planning (Wear OS is the next platform).
- **Derives from:** PRD §14; PDR-004.

## PDR-003 — Family-first escalation
- **Decision:** v1 escalates to **family/chosen contacts only**; RAXHA does not auto-dial emergency services. (The watch's own native 911 SOS remains available to the user.)
- **Rationale:** emergency-services integration is per-country regulated (Competency 15); family-first is buildable now and matches the beachhead's actual need.
- **Status:** Accepted (v1). **Revisit-when:** a specific market's regulatory path for services-dialing is cleared.
- **Derives from:** PRD §16; C15.

## PDR-004 — No Android/Wear OS in v1
- **Decision:** Android/Wear OS is **v1.1**, not v1.0.
- **Rationale:** focus + reliability on one platform first; cross-platform is the long-term moat but not the first release (Doctrine #1 native discipline applies per-platform).
- **Status:** Accepted (v1). **Revisit-when:** iOS v1 validated (coverage + retention).
- **Derives from:** PRD §5; PDR-002.

## PDR-005 — No medical diagnosis/treatment claims
- **Decision:** v1 makes **detection + notification** claims only. No diagnosis, treatment, condition-monitoring, cardiac/AFib/seizure, or fall-*prevention* claims.
- **Rationale:** the product expression of the Boundary (Doctrine #22); keeps v1 out of medical-device regulation and legally honest (Competency 15).
- **Status:** Accepted (v1, and boundary-permanent for the *claim*; specific cleared claims are a deliberate future program, C15).
- **Derives from:** Doctrine #22; PRD §15; C15.

## PDR-006 — Pricing deferred
- **Decision:** **Do not set pricing** until user interviews. Two models to test: family consumer subscription; elder-care agency per-resident.
- **Rationale:** pricing without customer research is a guess; the beachhead's willingness-to-pay is exactly what interviews must find.
- **Status:** **Open by design.** **Revisit-when:** after the first round of user/agency interviews.
- **Derives from:** PRD §12, §16.

## PDR-007 — The coverage promise (exact advertisable claim)
- **Decision:** The only coverage claim RAXHA makes is: *"RAXHA continuously monitors for meaningful safety events and, when confidence is sufficient, coordinates timely notification of the user's chosen contacts."* Never "we will always detect emergencies."
- **Rationale:** measurable, defendable, doctrine-consistent (Decisions #16/#19/#20); over-promising detection is both dishonest and unmeasurable.
- **Status:** Accepted (binding on all UX/marketing copy).
- **Derives from:** PRD §15; Doctrine #16/#19/#20.

## PDR-008 — The differentiator is the response layer, not detection
- **Decision:** RAXHA competes and is sold on the **independent risk engine + coordinated family response + coverage assurance + elder-invisible experience** — *not* on out-detecting the platforms.
- **Rationale:** detection commoditizes (platforms improve it for free); the response/assessment/coverage layer is the defensible, ownable moat (B1, B10, C15). (Its architectural expression is ADR-002/-004.)
- **Status:** Accepted (strategic).
- **Derives from:** North Star §4; PRD §3; B1/B10/C15.

## PDR-009 — Business model
- **Decision:** v1 = **family-pays consumer subscription** (freemium: basic alerts free; premium = multi-contact escalation, voice calls, coverage history, responder card). **Parallel:** elder-care agency/facility pilots (per-resident).
- **Rationale:** consumer motion = fastest users + the shadow-data flywheel; agency motion = the larger long-term, reimbursement-adjacent prize (C15).
- **Status:** Accepted (structure); **numbers deferred (PDR-006).**
- **Derives from:** PRD §12.

## PDR-010 — LTE-watch-standalone deferred
- **Decision:** The no-iPhone / LTE-watch-only elder is **v1.1+**, not v1.
- **Rationale:** watch-autonomous SOS adds device-matrix and QA cost; validate the core (iPhone-paired) product first.
- **Status:** Accepted (v1). **Revisit-when:** v1 validated; segment demand quantified.
- **Derives from:** PRD §13; PDR-002.

## PDR-011 — Responder info card is information-sharing, not monitoring
- **Decision:** The responder card (allergies, meds, contacts) is **user/family-entered information shared with responders at incident time** — not a medical-monitoring feature and not RAXHA-authored medical content.
- **Rationale:** stays inside the Boundary (Doctrine #22) while giving responders the most valuable 10 seconds (the physician's ask, B4/B10).
- **Status:** Accepted (v1).
- **Derives from:** PRD §4; Doctrine #22; B4/B10.

---

## Policy
PDRs are **revisable product truth** (Doctrine #12); the architecture (ADR-000) is designed so any PDR can flip without an architecture change. Only **PDR-006 (pricing)** is open by design; the rest are Accepted for v1. Detailed/future product decisions append here as PDR-012+ and must not contradict the North Star or the Boundary (PDR-005 / Doctrine #22).
