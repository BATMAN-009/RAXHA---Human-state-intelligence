# RAXHA Implementation

> **The sticky note (read before every session):**
> **Ship the smallest system that can earn real trust. Measure everything. Believe evidence over intuition. Preserve history. Earn the right to expand.**
>
> Two logbooks live here from day one: [Notebook A — assumptions disproven](NOTEBOOK-A-ASSUMPTIONS-DISPROVEN.md) · [Notebook B — unexpected truths](NOTEBOOK-B-UNEXPECTED-TRUTHS.md). AI's role in this tier: **pair architect, not autonomous builder** — design reviews, trade-off analysis, audits, failure analysis, RFC critiques; architecture and implementation decisions stay with the founder.

> **Status: PHASE 0 IN PROGRESS** (begun 2026-07-15 on the founder's explicit "start building" instruction in session; scoped to the RFC-invariant subset — pure core, frozen 08B objects, FSM, ports, replay harness, CI). Founder queue still open, tracked not blocking (per [Certificate 15](../engineering/15-ENGINEERING-READINESS-CERTIFICATE.md) and the [RFC register](../engineering/rfcs/RFC-REGISTER.md) sequencing note): ① sign Certificate 15 (line remains blank — no AI signs it), ② decide RFC-001…007 (RFC-001/-002 shape the fall path's entry conditions, which are deliberately NOT coded yet), ③ Competency-15 answers (Academy freeze; not a code blocker), ④ actions A1–A4. Everything needed to build already exists in `../engineering/` — this tier adds no design documents, only code and the evidence it generates.

## Phase 0 — the first work (per Roadmap 14 Part A/B)

```
implementation/
├── core/            RaxhaCore — PURE (zero platform imports; ADR-011)
│   ├── domain/      HumanState, Incident, EscalationState, RiskScore… (exactly the 08B objects)
│   ├── fsm/         Escalation FSM (write-ahead, persisted deadlines — ADR-105)
│   ├── state/       Human State Engine (ADR-102)
│   ├── risk/        Risk Engine v0 (rule-based — TD-1)
│   ├── policy/      Policy Engine (deterministic; veto contract structural — ADR-104)
│   └── ports/       MotionSource, VitalsSource, LocationSource, Clock, PeerLink,
│                    AlertTransport, HealthRecordStore, Inference (from B13/12)
├── harness/         Replay harness + trace corpus (VV-101/110 live here — Phase 0's exit gate)
├── mobile/          (Phase 1+) watchOS/iOS apps — adapters implementing the ports
├── backend/         (Phase 6+) Delivery & Coordination
└── shared/          contracts/schemas generated from 08B — never hand-redefined
```

**Phase 0 exit gate (no progression without it):** VV-101 (determinism rig) and VV-110 (contract rig) operational and producing evidence artifacts. Then Phase 1 (Sensing) per 14 Part B.

**Standing rules in force here:** frozen vocabulary only (08B-A) · every I/O behind a port (ADR-011) · no LLM in the decision path (D03/ADR-008) · foundation conflicts become RFCs, never workarounds (00A) · the quality of this code is measured by whether it satisfies the contracts (12), tests (13), and evidence requirements — not by elegance.

**Before every tempting shortcut, one question:** *Am I paying down uncertainty, or borrowing against it?* Borrowing is sometimes right — startups do it — but every borrow is **written down** (TD register, 14 Part D). Undocumented debt is the only kind that's forbidden.
