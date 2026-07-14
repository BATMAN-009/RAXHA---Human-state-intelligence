# Decision Confidence Register

> **Distinct from the Evidence Register on purpose:** *evidence validates assumptions; reality changes product decisions.* This tracks **founder product decisions** — each with how confident the founder is, why, and the trigger that should force a revisit. It complements [PDR-000](07A-PDR-000-Product-Decisions-Register.md) (which records *what* was decided) by adding *how firmly* and *what would change it.*
>
> **Boundary:** the **Confidence** column is a founder risk-judgment — I do not set it. The `evidence-informed suggestion` is exactly that: a suggestion from the Evidence Register / audits, for the founder to confirm or override. Confidence levels: **High** (validated or low-regret) · **Medium** (reasoned, unproven) · **Low** (untested, high-regret-if-wrong).

| Decision (PDR) | Founder Confidence | Evidence-informed suggestion | Why | Revisit trigger |
|---|---|---|---|---|
| **Elderly-alone beachhead** (PDR-001) | ☐ ___ | *High* — largest, clearest pain; strongest evidence base | The problem is real and acute; competitors under-serve it | Customer interviews contradict pain intensity; agency channel outperforms consumer |
| **Apple-first** (PDR-002) | ☐ ___ | *Medium* — best detection + one reliable platform, but see E-06/E-07 | Fastest path to a working detection engine RAXHA can ride | Android/Wear traction demand; Apple entitlement denial (H1); Family Setup test (SPIKE-002) reshapes the shape |
| **iPhone-required v1** (PDR-002/010) | ☐ ___ | **Low-Medium — actively contested by E-07/E-09; may flip to Family-Setup watch-only** | Simplicity + tighter QA | **SPIKE-002 result** — if fall-detection works on managed watch, RFC-005 may replace this |
| **Family-only escalation** (PDR-003) | ☐ ___ | *Medium* — simplest + buildable now; regulatory-clean | Emergency-services integration is per-country regulated | Enterprise/agency customers need services dispatch; a specific market's path clears |
| **No medical claims / Boundary** (PDR-005) | ☐ ___ | *High* — legal/ethical shield; boundary-permanent for the claim | D22; keeps v1 out of device regulation | Only via a deliberate cleared-claim program (C15), never casually |
| **Subscription business model** (PDR-009) | ☐ ___ | **Low — untested; pricing deliberately deferred** | Fastest to real users + the data flywheel | **Pricing/willingness-to-pay interviews** (the deferred PDR-006) |
| **Response-layer is the moat** (PDR-008) | ☐ ___ | *Medium-High* — AUDIT-001 confirmed detection commoditizes; moat = Coverage Assurance + post-ack loop + agency | Defensible where Apple structurally won't go | Apple ships deep family-response (iOS Check In is the warning shot) |
| **Night/charging coverage** (RFC-004, pending) | ☐ ___ | **undecided — E-10 False: no night coverage with one watch** | — | This is an open RFC decision, not yet a decision |

**How to use:** at each Founder Review, set/confirm every Confidence cell. A **Low**-confidence decision on the critical path is a flag to *buy evidence before over-committing* (interviews, a spike, a pilot) — not to stop, but to avoid betting the build on an untested belief. When a revisit trigger fires, the decision returns here and, if it changes, flows out as a PDR revision + RFC (never a silent edit — 00A).

*New this cycle: T-7 (caregiver-as-adversary, THREAT-MODEL-001) may add a product decision — "anti-surveillance guarantee: family gets incident-time location only, never continuous tracking" — pending RFC-007. If accepted, it enters this register at High confidence (it's both an ethics floor and a differentiator).*
