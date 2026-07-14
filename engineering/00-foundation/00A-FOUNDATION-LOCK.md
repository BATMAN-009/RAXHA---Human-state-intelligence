# 00A — Foundation Lock

> **Foundation version: v1.0-prebuild** (locked 2026-07-14). This document freezes the foundational layer of RAXHA. Downstream artifacts — starting with the Master Architecture Blueprint (08) — are built *from* these documents and **may not silently modify them.** This is how aerospace and medical-device programs prevent architecture drift: the foundation is a fixed reference, changed only through a controlled process.

---

## Frozen documents (v1.0-prebuild)

| ✓ | Document | File |
|---|---|---|
| ✓ | Engineering Doctrine (D01–D22 + mission) | [01-ENGINEERING-DOCTRINE.md](../../academy/01-ENGINEERING-DOCTRINE.md) |
| ✓ | Knowledge Graph | [03-KNOWLEDGE-GRAPH.md](../../academy/03-KNOWLEDGE-GRAPH.md) |
| ✓ | Canon (single index D01–D22) | [05-RAXHA-CANON.md](../../academy/05-RAXHA-CANON.md) |
| ✓ | North Star | [RAXHA-NORTH-STAR.md](RAXHA-NORTH-STAR.md) |
| ✓ | PRD (Product Spec v1.0) | [07-RAXHA-PRODUCT-SPEC-v1.md](../01-product/07-RAXHA-PRODUCT-SPEC-v1.md) |
| ✓ | PDR-000 (Product Decisions Register) | [07A-PDR-000-Product-Decisions-Register.md](../01-product/07A-PDR-000-Product-Decisions-Register.md) |
| ✓ | ADR-000 (Core Architecture Decisions + Traceability Matrix) | [07B-ADR-000-Core-Architecture-Decisions.md](../02-architecture/07B-ADR-000-Core-Architecture-Decisions.md) |
| ✓ | Data Dictionary **Part A** (Controlled Vocabulary) | [08B-DATA-DICTIONARY.md](../02-architecture/08B-DATA-DICTIONARY.md) |

*(Not frozen — these are the downstream WORK: Blueprint (08), Responsibility Matrix (08A), Data Dictionary Part B (08B), SRS (09), Hazard Analysis (10), detailed ADRs (11), API specs (12), V&V (13), Implementation Roadmap (14). The Academy modules 00–06 are the source material.)*

---

## The Rule

**The Blueprint — and every downstream artifact — SHALL NOT modify a frozen document.**

If, while building a downstream artifact, a **conflict** with the foundation is discovered (the foundation is wrong, contradictory, or insufficient):

1. **STOP.** Do not silently rewrite the foundation, and do not quietly work around it.
2. **Create an RFC** (`RFC-NNN`): name the frozen document + section, state the conflict precisely, propose the change, and give the rationale + impact.
3. **Wait for approval.** Only an approved RFC may edit a frozen document.
4. On approval: apply the change, **bump the foundation version** (v1.0 → v1.1), and note the RFC in the changed document.

**Never silently rewrite the foundation.** A conflict surfaced as an RFC is a healthy signal; a foundation edited mid-build without a trace is architecture drift.

---

## Why

The whole point of the North Star → PDR → ADR → Data Dictionary chain is that the Blueprint has a *stable* set of constraints to derive from (the "invents nothing" rule, 06 §4). If the Blueprint could edit those constraints as it goes, "derived from" would be circular and meaningless. Locking the foundation makes derivation real: the architecture is provably a *consequence* of the foundation, not a co-author of it.
