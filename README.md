# RAXHA

Three separated concerns, three lifecycles. This split (2026-07-14) mirrors how mature organizations keep teaching, design, and code from contaminating each other.

```
RAXHA/
├── academy/          Teaching assets — the philosophy & science. FREEZES (RFC-only after v1.0).
├── engineering/      Living design documents — what will be built. Evolves under governance.
└── implementation/   Source code (empty until the doc set is complete).
```

| Tier | Purpose | Changes | Authority |
|---|---|---|---|
| **academy/** | Teaches the science, doctrine, and philosophy (16-module curriculum, Doctrine D01–D22, Canon). | Rarely; frozen at v1.0, edited only via Academy RFC. | The **source of the Doctrine & Canon** that engineering derives from. |
| **engineering/** | Defines *what will be built* — North Star → PRD → PDR → ADR → Blueprint → SRS → Safety → API → V&V → Roadmap. | Actively, but the **foundation is locked** (see `engineering/00-foundation/00A-FOUNDATION-LOCK.md`); conflicts → RFC. | Derives from academy's Doctrine/Canon. |
| **implementation/** | The actual mobile + backend + shared code. | Continuously, once started. | Derives from engineering specs. |

**Dependency direction (never reversed):** implementation → engineering → academy. Code obeys the specs; specs obey the doctrine.

**When reality disagrees with Engineering (the inter-tier protocol):** don't change code first; don't change doctrine first — **trace the disagreement.** Ask, in order: *Was the assumption wrong? Was the architecture wrong? Was the implementation wrong? Was the requirement wrong?* The answer — not the urgency — determines which layer changes, and it changes via an RFC (+ a Notebook-A entry). Treating a disagreement as the beginning of v1.1, not as failure, is what keeps all three layers healthy.

**The asset to protect above all:** traceability. Today, any subsystem can answer *why do I exist → which doctrine created me → which hazard requires me → which requirement specifies me → which test proves me.* Very few products can. Every shortcut is measured against whether it preserves that property.

**Eventual repository split (when coding starts):** `raxha-academy` (docs only), `raxha-engineering` (design docs only), `raxha-platform` (source). This folder layout is the pre-repo staging of that separation.

**Start here:** [engineering/README.md](engineering/README.md) for the design-document sequence; [academy/README.md](academy/README.md) for the philosophy and its freeze policy.
