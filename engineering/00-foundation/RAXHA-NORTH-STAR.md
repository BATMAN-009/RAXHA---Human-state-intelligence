# RAXHA — The North Star (one page)

> The product intent every engineering decision answers to. Read this before the PRD (07) and before the Master Architecture Blueprint (08). If a design choice doesn't serve one of these five answers, it is out of scope. Bound by Decision #22 (RAXHA detects and notifies; it never diagnoses or treats).

**1. Who is the customer?**
Independent older adults living alone (the *wearer*), monitored by their adult children / family caregivers (the *response network* and the *economic buyer*). Four roles, one buying unit: primary user (the elder), secondary user (the family monitor), economic buyer (usually the family; later, elder-care agencies), response recipient (the family/caregivers).

**2. What problem are we solving?**
When an older adult living alone falls or collapses, they often **cannot summon help** — phone out of reach, unconscious, or confused — and their family may not know for hours. The family lives with chronic, low-grade dread: *"What if it happens and I don't find out in time?"*

**3. Why does this problem exist today?**
- Medical pendants carry stigma → they aren't worn → they protect no one (the #1 documented failure).
- Smartwatch fall detection is good at *detecting* but ships a **thin family-response layer** — a single contact or a 911 call, no coordinated, acknowledged, "is Mom protected right now" experience across the family, and no assurance the system is even active.
- No one owns an **independent, privacy-preserving, evidence-based assessment-and-response layer** that works across the signals a person already emits.

**4. Why is RAXHA uniquely positioned?**
RAXHA maintains its **own deterministic risk engine** (platform detections are *inputs*, not the verdict — so it survives any single vendor's changes), and pairs it with the layer the platforms leave open: a **reliable, coordinated, privacy-preserving family response network + continuous coverage assurance + an experience invisible enough that the elder actually keeps the watch on.** Detection commoditizes; this layer is the defensible moat. And RAXHA is architected — not merely promised — to never sell or misuse the most sensitive data a person emits (Decision #21).

**5. How will we know we've succeeded?** (measurable)
- **Coverage:** median % of day a wearer is actually protected (worn + charged + pipeline alive) — the leading indicator before any fall.
- **Response reliability:** trigger → family-acknowledged **p99 latency** (seconds), and delivery success rate.
- **Trust economics:** false alarms per wearer-week *and* an estimated-miss surrogate, watched together (never optimize one alone); non-wear rate; subscription retention.
- **North-star outcome:** *true emergencies in which the family was informed in time to act.*

---
*Reading order: North Star → [PRD (07)](../01-product/07-RAXHA-PRODUCT-SPEC-v1.md) → [Master Architecture Blueprint (08)] → SRS → Safety artifacts → Implementation (sequence in [06-PHASE-2-TRANSITION.md](06-PHASE-2-TRANSITION.md)).*
