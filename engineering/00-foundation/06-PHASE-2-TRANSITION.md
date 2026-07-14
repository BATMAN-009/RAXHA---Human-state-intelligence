# Phase 2 — Vertical Conversion: Operating Playbook

> **Adopted 2026-07-14.** The Core Arc (Competencies 1–15 + B1–B14) is materially complete. This document governs the shift from **horizontal learning** (adding knowledge) to **vertical conversion** (knowledge → engineering artifacts → code). It is a *process* document for the post-freeze phase; it adds no competency, university, or doctrine, so the Structural Freeze is untouched.
>
> Mode: **Principal Architect & Chief Scientist / auditor**, not tutor. Honor all 22 Doctrine Decisions and the RAXHA Boundary (#22) throughout.

---

## 1. Two independent readiness gates (do NOT conflate)

| Gate | Meaning | Gated on | Status |
|---|---|---|---|
| **Documentation Freeze v1.0** | A clean, publishable snapshot of the Academy | Competency-15 mastery gate closed **+** audit Findings 1–6 cleared | **Open** (blockers listed below) |
| **Build-Start** | Permission to begin architecture + implementation planning | No CONFIRMED finding at severity **≥ High** | **✅ MET** (audit found none) |

**Consequence:** editorial fixes (doctrine reorder, graph consolidation) and build work (Master Blueprint, engineering artifacts) proceed **in parallel**. A renumbering does not block engineering.

## 2. Severity ladder (objective — every finding maps to exactly one)

| Severity | Definition |
|---|---|
| **Critical** | Would create incorrect *safety behaviour* |
| **High** | Would produce incorrect *architecture* |
| **Medium** | Creates *inconsistency* |
| **Low** | *Documentation quality* |
| **Info** | Observation only |

## 3. Audit rules of engagement (the 7 upgrades)

1. **No-hallucination rule.** If a defect cannot be proven from the existing files, state **"NO DEFECT FOUND."** Never speculate a defect into existence.
2. **Severity is objective** — use §2's ladder; no subjective High/Med/Low.
3. **Anti-perfectionism.** The goal is *correctness, not maximizing defect count.* Do not hunt endlessly for microscopic issues.
4. **Before/After diffs required.** Every fix ships as a unified diff — `Before:` / `After:` / `Reason:` — not a description.
5. **Verify line references.** Substance can be right while line numbers drift; confirm `file:line` against the actual file before reporting.
6. **Distinguish the three truths** (Decision #12): scientific / platform / product.
7. **Close with the risk question** (§6).

## 4. Master Architecture Blueprint — required artifacts (Deliverable C, expanded)

**Prerequisites (both exist):** [PDR-000](../01-product/07A-PDR-000-Product-Decisions-Register.md) (product decisions) and [ADR-000](../02-architecture/07B-ADR-000-Core-Architecture-Decisions.md) (the 15 architecture decisions). The Blueprint references PDR and ADR IDs per subsystem — that is what makes it traceable rather than arbitrary.

**The Blueprint stays in its lane.** It answers **only** *"how is the system composed?"* — subsystems, their relationships, and data flow. It does **not** restate *why the product exists* (North Star), *who the customer is* (PRD), *why a choice was made* (ADR/PDR), *API details* (12), or *implementation requirements* (SRS). Each artifact in its lane = maintainable; a Blueprint that explains everything becomes a 150-page swamp. Keep it composition-only.

**The Blueprint invents NOTHING — hard governance rule (avionics/medical discipline).** Every section MUST open with a **`Derived From:`** block citing its origins (PDR / ADR / Doctrine # / Canon / PRD §). **A section that cannot fill `Derived From:` cannot exist** — no subsystem, interface, or data flow appears because it seems nice; each appears because something higher *requires* it. Example: *Risk Engine — Derived From: ADR-002/-004/-006/-008/-012/-014 · PDR-008 · Doctrine #16/#17/#18 · PRD §4.* This is how the architecture stays free of drift. (Decision references use the **single canonical index** — see §10.)

**Mandated opening sentence of the Blueprint (verbatim):** *"RAXHA is not a collection of sensors, apps, or AI models. It is a deterministic Human State Intelligence Platform whose purpose is to transform uncertain evidence into the most appropriate human response while preserving trust, privacy, and safety."* Everything in the Blueprint traces back to that sentence.

**Two-part structure (durable vs. swappable):**
- **Part A — Conceptual Blueprint:** NO technologies. Pure architecture — `Human → Sensors → Human State Engine → Risk → Policy → Response` — plus the diagrams below at the conceptual level. This part should almost never change.
- **Part B — Implementation Blueprint:** the same architecture bound to concrete tech (watchOS/iOS, Postgres, push/SMS/voice, etc.). This part changes as technology does; Part A does not.

**Foundation is LOCKED** ([00A-FOUNDATION-LOCK.md](00A-FOUNDATION-LOCK.md)): the Blueprint may not modify any frozen document. On conflict → STOP → RFC → approval (never silently rewrite).

**Five more construction rules (adopted 2026-07-14):**
- **Every subsystem has EXACTLY five sections + one footer, nothing else:** *Purpose · Inputs · Outputs · Failure Behaviour · Evidence Produced*, then `Derived From:` (North Star / PRD / PDR / ADR / Doctrine D##). No implementation, no APIs, no algorithms.
- **No interfaces/APIs in the Blueprint.** Say *"Risk Engine publishes a Risk Assessment,"* never *"POST /v1/risk."* API contracts belong in artifact 12.
- **Part A diagrams are technology-free.** Draw *Watch → Human State Engine → Risk Engine → Policy Engine → Response Engine*, never *Swift / FastAPI / Supabase / Redis*. Technology appears only in Part B.
- **Tech-independence test for Part A:** Part A must remain correct if Swift→Kotlin, Supabase→AWS, PostgreSQL→FoundationDB, Apple Watch→custom wearable. If Part A changes because technology changed, it was implementation, not architecture — move it to Part B.
- **Vocabulary is fixed** (08B Part A): use Signal/Observation/Evidence/Human State/Risk/Policy Decision/Incident/Alert with their frozen meanings.

Save as `08-MASTER-ARCHITECTURE-BLUEPRINT.md`. Must contain **all ten standard diagrams** (text-style, self-contained), and each subsystem cites its **Derived From** IDs:

1. Context Diagram · 2. Container Diagram · 3. Component Diagram · 4. Sequence Diagram (per path: fall / crash / cardiac / manual SOS) · 5. Deployment Diagram · 6. **Trust Boundary Diagram** · 7. **Failure Propagation Diagram** · 8. **Latency Diagram** (per path) · 9. **State Machine Diagram** (the escalation FSM) · 10. Data Flow Diagram (with the data-plane rule, Decision #5, drawn explicitly).

Plus, for each subsystem: single responsibility · what it produces as *evidence* · what happens if it *fails* · who owns each decision (Decision #17). Frame RAXHA as a **Human State Intelligence Platform** whose core asset is a deterministic, evidence-based **Human State Intelligence Engine**; apps/watches/backend/dashboard are interfaces around it. Every subsystem cites where each relevant Decision (#1–#22) is enforced.

## 5. Traceability spine (the medical-device discipline, B14)

Every architecture statement and every engineering artifact carries its lineage. Two parallel origins — product and architecture — converge in the Blueprint:

```
North Star ─┬─▶ PDR-00X (product truth, revisable)  ─┐
            └─▶ Doctrine # → ADR-00X (architecture)  ─┴─▶ Blueprint component → SRS requirement → Validation Test
```

This chain IS the Traceability Matrix (artifact 12 / §7). Nothing enters the build without a traceable origin; nothing safety-critical ships without a validation test at the end of its chain. A PDR flip re-derives only the product-dependent blocks; the ADR-anchored architecture is unaffected.

## 6. Standing closing question (every Blueprint/audit ends with it)

> **"If RAXHA were built exactly from these documents today, what are the five largest architectural risks remaining?"**

Answered explicitly, ranked, each with the evidence for it. This outranks any wording/grammar finding.

## 7. The Phase-2 engineering-artifact backlog (Deliverable D, restructured 2026-07-14)

The curriculum converts into **production engineering documentation** — the foundation any engineering team (or Claude/Codex/etc.) implements from consistently. Organized in **three dependency-ordered layers**, because each layer needs the one before it. **The PRD precedes everything** — you cannot write requirements for a product you have not defined.

**Artifact #−1 — The North Star (`RAXHA-NORTH-STAR.md`).** One page, five questions: who is the customer / what problem / why it exists today / why RAXHA is uniquely positioned / how we'll know we succeeded (3–5 measurable metrics). Read before the PRD and Blueprint; keeps every downstream design grounded in product intent, not abstract technical elegance. ✅ WRITTEN.

**Artifact #0 — Product Requirements Document (`07-RAXHA-PRODUCT-SPEC-v1.md`).** *What RAXHA v1 is* (PRD answers "what"; the Blueprint answers "how"). Contents: **exactly who the first customer is** (the beachhead — the load-bearing product decision), the problem solved, **what is explicitly NOT solved (v1 scope boundary)**, screens, user journeys, onboarding, permission flows, notification design, subscriptions/business model, edge cases, and — critically for a safety product — **failure UX and recovery UX**. Must honor Decision #22 (RAXHA detects/notifies; never diagnoses/treats) in every claim it makes. *"If Apple asked what RAXHA is, this answers."*

**Layer 1 — Architecture (defines the system; every engineer sees the same product):**
| # | Artifact | Primary sources |
|---|---|---|
| 1 | **Master Architecture Blueprint** (`08-…`, 10 diagrams, §4) | B1, B13, whole KB |
| 2 | **System Requirements Specification (SRS)** — architecture → verifiable requirements | Blueprint, Doctrine, competencies |
| 3 | **Domain Model + Data Flow** | B13 (DDD), Decision #5 |
| 4 | **Architecture Decision Records (ADRs)** — one per key decision | the 22 Decisions |

**Layer 2 — Safety (where RAXHA differs from a normal startup):**
| # | Artifact | Primary sources |
|---|---|---|
| 5 | **Hazard Analysis (FMEA / STPA)** | every §14 failure table, Decision #20 |
| 6 | **Risk Management File (ISO 14971)** — accrues from day one (B14: unretrofittable) | §14 tables, C15, B14 |
| 7 | **Threat Model + Trust/Failure boundaries** | B11, Blueprint diagrams 6–7 |

**Layer 3 — Build (coding becomes almost mechanical):**
| # | Artifact | Primary sources |
|---|---|---|
| 8 | **API Specification** (watch↔phone↔cloud↔responder) | B7, B10, B14 |
| 9 | **Database schema + Data Dictionary** (every signal, unit, quality field, retention) | B4, B5, C-track |
| 10 | **Mobile + Backend specs** | B2–B6, B9, B10 |
| 11 | **Verification & Validation Plan + Test Specs + Replay framework + CI** | B12, C14 (V3), C15 |
| 12 | **Traceability Matrix** (the §5 spine — binds all of the above) | doctrine ↔ competency ↔ spec ↔ component ↔ test |

**Execution sequence (revised 2026-07-14 — ADR-000 established *before* the Blueprint so it has stable engineering constraints to reference):**
`North Star → PRD → ADR-000 (core architecture decisions) → 08 Blueprint (Part A conceptual + Part B implementation) → 09 SRS → 10 Hazard Analysis (FMEA+STPA) → 11 individual/detailed ADRs → 12 Interface & API specs → 13 V&V Plan → 14 Implementation Roadmap → code.`
Foundational ADR-000 comes first; detailed ADRs (11) later expand individual decisions without changing the core architecture.
Within the build, code starts at the **Sensor Framework** (Data Dictionary + SRS slice) → **Risk Engine** (SAD + ADRs + Hazard Analysis — the biggest asset) → Backend/API → V&V binds it.

## 8. The frozen document hierarchy (Phase-2 — no more foundational docs after this)

The Phase-2 documentation structure is now **complete and frozen**. Refine and implement these; do not add new *foundational* document types. (Content within each still evolves; the *set* does not.)

```
00  Curriculum            07   North Star
01  Engineering Doctrine  07A  PDR-000  Product Decisions Register
02  Amendment Queue       07B  ADR-000  Core Architecture Decisions
03  Knowledge Graph       08   Master Architecture Blueprint (Part A conceptual · Part B implementation)
04  Academy Expansion     08A  Subsystem Responsibility Matrix
05  Canon                 08B  Data Dictionary & Controlled Vocabulary
06  Phase-2 Transition    09   SRS
                          10   Hazard Analysis (FMEA + STPA)
                          11   Detailed ADRs (expand individual decisions; must not contradict 07B)
                          12   API / Interface Specs (+ Traceability Matrix)
                          13   Verification & Validation Plan
                          14   Implementation Roadmap
```
*(07 North Star · 07A PDR-000 · 07B ADR-000 sit between 06 and 08.)*

**08A — Subsystem Responsibility Matrix** (right after the Blueprint): `Subsystem | Owns | Never owns | Inputs | Outputs | Failure behavior` — e.g., *Risk Engine: owns risk estimation · never owns alert delivery · in: Human State · out: Risk Score · fails to "unknown," never silent.* The fastest onboarding artifact.

**08B — Data Dictionary & Controlled Vocabulary** (right after 08A; reorder adopted 2026-07-14): one glossary, one meaning (Signal→Observation→Evidence→Human State→Risk→Policy Decision→Incident→Alert), so every API/schema/test/state-machine shares a language *before* the SRS uses it. Part A (vocabulary) is frozen; Part B (object field schemas) completes after 08/08A. ✅ written.

**Decision Traceability Matrix** (Appendix A of ADR-000 / 07B): every canonical decision D01–D22 → *Enforced by · Subsystem · Validation · Test · Evidence*, so no decision is left as "philosophy." ✅ **built** (single-index reconciliation done — §10).

## 10. Single canonical decision index — ✅ RESOLVED 2026-07-14
**Decision:** the **Doctrine IDs D01–D22 are the ONLY numbering in the project.** Done: (1) Canon (05) rewritten to use D01–D22 (its independent numbering removed); (2) the three Canon-only principles folded in as **corollaries** — veto-contract under **D17**, contradiction-is-information under **D18**, every-claim-carries-evidence under **D21**, measurement-is-not-meaning under **D22**; (3) the three missing decisions **D07 (latency), D08 (shadow mode), D09 (coverage telemetry)** added to the Canon; (4) Decision Traceability Matrix built against D01–D22 only (no second index). Every future doc cites `D17`/`D22` unambiguously.

## 9. What stays frozen (curriculum)

No new competencies, universities, sensors, or Doctrine Decisions. The 22 Decisions, the Canon, the two-track curriculum, and the §1–22 (A-track) template are v1.0-final. Phase 2 *consumes* them; it does not extend them. New structural ideas still queue in `02-AMENDMENT-QUEUE.md`.
