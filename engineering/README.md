# RAXHA Engineering

The design documents — *what will be built*. Each derives from the one before and, ultimately, from the academy's Doctrine (D01–D22). The **foundation is locked** ([00-foundation/00A-FOUNDATION-LOCK.md](00-foundation/00A-FOUNDATION-LOCK.md)); a conflict with a frozen document is resolved by RFC, never a silent edit.

## The sequence
```
North Star → PRD → PDR → ADR → [Foundation Lock] → Blueprint → Responsibility Matrix
   → Data Dictionary → SRS → Hazard Analysis → Detailed ADRs → API Specs → V&V → Roadmap → Code
```

## Folder map & status
| Folder | Contents | Status |
|---|---|---|
| **00-foundation/** | North Star · Foundation Lock (00A) · Phase-2 Transition playbook (06) | ✅ |
| **01-product/** | PRD (07) · PDR-000 Product Decisions (07A) | ✅ |
| **02-architecture/** | ADR-000 + Decision Traceability Matrix (07B) · **Master Architecture Blueprint (08)** · Responsibility Matrix (08A) · Data Dictionary Parts A+B (08B) | ✅ complete |
| **03-safety/** | **System Hazard Analysis (10A) ✅ · Risk Control Matrix (10B) ✅** — seed of the ISO-14971 RMF | ✅ |
| **04-specifications/** | **SRS (09) ✅ · Detailed ADRs 101–112 (11) ✅ · Interface Specification (12) ✅** — contract-first, 4 categories, dependency matrix | ✅ |
| **05-validation/** | **V&V Plan (13) ✅** — method-first VV-1xx…8xx, evidence packages, exit criteria, regression levels L0–L4, Assumptions Register, closed traceability chain | ✅ |
| **06-roadmap/** | **Engineering Readiness Roadmap (14) ✅** — build order + VV-gated phases, team boundaries, debt register, kill criteria, Architecture Stability Gate, Definition of Engineering Ready | ✅ |

## Rules in force (from 06 §4)
- **Blueprint invents nothing** — every section opens with `Derived From:`; no derivation → the section cannot exist.
- **Stay in lane** — Blueprint = composition only; APIs → specs, requirements → SRS, why → ADR/PDR.
- **Part A is technology-free**; technology lives only in Part B and passes the tech-independence test.
- **One decision index** — cite **D01–D22** everywhere (Doctrine = Canon numbering).
- **Vocabulary is frozen** — the controlled terms in `02-architecture/08B-DATA-DICTIONARY.md` Part A.

**ENGINEERING DOCUMENTATION IS COMPLETE (00A–15). ENGINEERING HAS NOT BEGUN.** *(Those are different sentences.)* Implementation opens on founder approval of the [Engineering Readiness Certificate (15)](15-ENGINEERING-READINESS-CERTIFICATE.md) — the Design-Freeze checkpoint. From here: RFCs for genuine architecture change, revisions to existing artifacts, implementation per the gated roadmap (14), and evidence from testing/operation. No new foundational document types.

**Current state:** Phase 1 (Academy): Competencies 1–14 ✅ · Competency 15 🟡 knowledge complete, mastery gate open · Doctrine/Canon/Knowledge Graph ✅ frozen. Phase 2 (Engineering docs): foundation/product/architecture/safety/specifications/validation/roadmap ✅ complete + readiness certificate prepared. Phase 3 (Implementation): ⏳ not started — awaiting certificate approval; Phase 0 = pure core + replay harness.

**Phase status (2026-07-14):** Documentation ✅ · Investigation ✅ **CLOSED** (SPIKE-001, AUDIT-001, THREAT-MODEL-001/002, Evidence Register, Decision Confidence Register — no further investigator work without new evidence) · Implementation ⏳ not started. **Operating rule, in force:** *no new documents unless implementation, hardware, users, or regulation create a question the existing documents cannot answer.* Open threads live in [rfcs/RFC-REGISTER.md](rfcs/RFC-REGISTER.md) (RFC-001…007) and [audits/EVIDENCE-REGISTER.md](audits/EVIDENCE-REGISTER.md); founder actions A1–A4.

**The current step is human, not documentary — the Founder Review:** read, without editing: 00A Foundation Lock · North Star · PRD (07) · PDR-000 (07A) · ADR-000 (07B) · Blueprint (08) · Readiness Certificate (15). Three questions only: *Is this still the company I want to build? Would I stake 5–10 years on this direction? Does anything here exist because AI generated it rather than because I believe it?* Anything not truly believed is removed — recorded as a founder RFC (version bump), never silently (00A applies to everyone, including us). **The survival bar for anything kept:** not "did AI write this?" but *"would I defend this decision to a customer whose parent was harmed if this assumption turned out to be wrong?"* Yes → keep. No → rewrite. Then: **Founder Review → Competency 15 (answered by the founder; AI critiques, never answers first) → freeze Academy v1.0 → sign certificate 15 → open implementation/ → Phase 0.**

**Standing change rule thereafter — every future change must be earned by one of exactly four things:** **Reality** (implementation exposed a gap) · **Evidence** (tests or field data disproved an assumption) · **Users** (real behavior contradicted the product model) · **Regulation** (a requirement actually changed). Never because "this document could be written a little better." That discipline is what separates an architecture from living documentation.
