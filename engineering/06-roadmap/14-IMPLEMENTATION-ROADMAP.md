# 14 — Engineering Readiness Roadmap

> **This is not a project plan.** It does not schedule sprints; it defines **what must become true before each phase is allowed to begin** — and when to deliberately stop. Progression is gated by VV evidence (13), not by calendar. It is the last engineering document before code: after this, improvements take the form of RFCs, revisions to existing artifacts, implementation, and evidence — **no new foundational document types** (00A discipline).

---

## Part A — Build Order (and why this order minimizes risk)

```
Phase 0  Scaffolding: pure core + replay harness + CI
Phase 1  Sensing Layer
Phase 2  Human State Engine
Phase 3  Risk Engine
Phase 4  Policy Engine            ← the veto gate lives here
Phase 5  Response & Escalation    ← the reboot gate lives here
Phase 6  Delivery & Coordination (backend)
Phase 7  Family App + Human Interfaces
Phase 8  Operations & Observability
──────── field phases ────────
Phase S  Shadow deployment (silent)
Phase α  Internal alpha (~10 wearers, family/friends)
Phase β  Private beta (~100 wearers, diverse)
Phase L  Launch
```

**Why this order:**
1. **Harness before subsystems (Phase 0):** every later gate needs the replay/CI evidence engine — building it first means every subsequent line of code is born testable (ADR-109; B14's CI-as-evidence).
2. **Data flows up, so build up:** each subsystem's *inputs* exist before it does (Sensing → HSE → Risk → Policy → Response) — no phase ever mocks its upstream for long, and integration risk is retired earliest where the physics lives.
3. **The decision spine before any UI:** the life-critical path (Phases 1–5) is provable in CI without a pixel drawn; UI (Phase 7) then renders *proven* state (B13 MVVM: view = f(state)).
4. **Backend after the device can stand alone:** tier autonomy (D04) is only honest if the device path was built and tested to work *without* the cloud first; the backend then adds coordination, not dependence (ADR-005/-007).
5. **Operations before humans depend on it:** drills, SLOs, and two-sided dashboards (Phase 8) must be live *before* shadow — you cannot ethically watch a fleet you cannot observe (D09/D20).

## Part B — Readiness Gates (no gate → no progression)

| Phase | Entry gate (what must already be true) | **Exit gate (VV evidence, all PASS)** |
|---|---|---|
| 0 Scaffolding | 00A foundation locked; 08B vocabulary frozen | Harness runs a trace end-to-end; **VV-101** (determinism rig) + **VV-110** (contract rig) operational and producing evidence artifacts |
| 1 Sensing | Phase 0 exit | **VV-109** (pre-event buffer), **VV-110** (IF-INT-01 contract), **VV-504** (wake-path latencies), initial **VV-503** power probe |
| 2 Human State | Phase 1 exit | **VV-105** (unknown-widening), IF-INT-02 contract, calibration plumbing present (ADR-108 — provenance fields flow end-to-end) |
| 3 Risk | Phase 2 exit | **VV-108** (spoofed-input rejection), IF-INT-03 contract, version stamping verified (SRS-302); v0 model registered in governance (ADR-112) |
| 4 Policy | Phase 3 exit | **VV-101** (full determinism), **VV-102 (veto suite — the L1 release gate, non-negotiable)**, **VV-103/104** (initial corpus recall + ADL FA), IF-INT-04 |
| 5 Response | Phase 4 exit | **VV-106** (reboot-mid-COUNTDOWN), **VV-201** (live reboot chaos), **VV-206** (device-side dedup), IF-INT-05 journal durability |
| 6 Backend | Phase 5 exit (device path stands alone) | **VV-203/204** (offline + cloud-outage), **VV-207/303** (dead-man), **VV-304** (share expiry), **VV-605** (ingest authn), **VV-702–705** (privacy audits) |
| 7 Family App | Phase 6 exit | **VV-801** (claims-language audit), **VV-802/803** (elder + responder usability), IF-HUM-01…05 contract behavior |
| 8 Operations | Phase 7 exit | **VV-301** (daily drill live and green ≥14 consecutive days), **VV-505** (heartbeat SLO), **VV-503** (battery matrix), two-sided dashboards (VV-401/402 infrastructure) operational |
| **S Shadow** | Phase 8 exit + **VA register reviewed, no red** | **VV-401** (FA/wearer-week ≤ target) **+ VV-402** (miss-surrogate in bounds — reviewed together), **VV-403** (field ECE ≤ target), **VV-404** (baseline behavior), **VV-405** (representation) |
| **α Alpha** (~10) | Shadow exit; alerts enabled for consenting testers | Coverage KPI ≥ target; zero unresolved Sev-1; every real cancel/ack UX-reviewed (VA-08) |
| **β Beta** (~100, age/geography-diverse) | Alpha exit + VV-205 (multi-vendor failover) | FA/wearer-week ≤ target *sustained*; coverage median ≥ target across the device matrix; VA-03 representation holds; L3 release set green |
| **L Launch** | Beta exit + **Release Decision rule (13)** + **Architecture Stability Gate (below)** | Continuous: L3 per release; L4 periodically |

## Part C — Team Expansion (roles and boundaries, not names)

| Stage | Team | Ownership boundaries (per 08A) | Handoff discipline |
|---|---|---|---|
| Phases 0–5 | **Founder (+AI tooling)** | Everything; the docs are the second engineer | Every decision lands in an artifact, never only in chat (the standing question) |
| Phases 6–8 | **+1 → 2 engineers** | Split: *Device* (Sensing→Response, watch/phone) vs *Backend+Ops* (Delivery, drills, observability) | 08A Never-Owns column is the org chart; interfaces (12) are the handoff contracts |
| Shadow–Beta | **4 engineers** | + *V&V/QA owner* (owns 13 + corpus + evidence packages) + *Family-experience owner* (Phase 7 + usability) | No one owns a subsystem and its verification simultaneously |
| Launch | **6–8** | + Ops/on-call rotation (**≥4 rotating** — a daily-drill Sev-1 pager is a 24/7 duty, B10) + privacy/security ownership (B11 audits) | RFC process is the only path to foundation changes |

## Part D — Technical Debt Register (living — shortcuts must carry their expiry)

| # | Debt | Accepted because | **Must be removed before** |
|---|---|---|---|
| TD-1 | v0 Risk model is rule-based/heuristic (not learned) | Interpretable, shippable, replay-testable; honest for v1 claims | Any ML-grade recall claim; V2 personalization (VV-107 then applies to the learned artifact) |
| TD-2 | Population-level calibration (not per-user) | Cold-start reality; per-user needs tenure data | Personalized thresholds enabled (ADR-108 per-user stage) |
| TD-3 | Single telephony vendor at alpha | Integration cost; alpha scale tolerates | **Beta entry** (VV-205 failover is a beta gate) |
| TD-4 | Replay corpus manually curated, simulated-fall-heavy | No fleet data exists yet | Shadow exit (VA-01/VA-02: corpus refreshed from shadow traces) |
| TD-5 | Alert payload TLS+minimization, not yet E2E-encrypted | E2E key-management (B11) is real work; minimization already bounds exposure | Any "end-to-end encrypted" marketing claim (VV-801 guards); target V1.1 |
| TD-6 | Dead-man reconciliation is simple timeout-based | Correct-if-conservative; richer reconciliation needs field heartbeat data | Beta exit (tune against VV-505 SLO distribution) |
| TD-7 | Battery budgets provisional (bench, not fleet) | No fleet yet | Launch (VV-503 across real device matrix) |

*Rule: adding a row requires an "accepted because" and a "removed before" — undated debt is architecture rot in disguise.*

## Part E — Kill Criteria (when we deliberately stop — the Academy discipline, applied to ourselves)

| Trigger | Action |
|---|---|
| Shadow FA/wearer-week exceeds target after **two** full tuning cycles | **Do not enable alerts.** Return to detection/context design (C1/C12); enabling anyway would spend trust we cannot refill (D19) |
| Field calibration (VV-403) fails to converge after recalibration cycles | Block Risk-dependent phases; Blueprint risk #1 is live — fall back to conservative rule thresholds + human-in-loop confirmation |
| Coverage median below target in beta (worn+alive+linked) | Halt launch; the promise fails at D09/D14 — attack non-wear/UX before scale |
| Battery exceeds budget on target devices after optimization pass | Halt; a safety device that dies daily protects nobody — re-tier sensing (ADR-101) |
| Elder usability (VV-802) below threshold after **two** design iterations | Redesign before beta; a cancel button elders can't use converts H-02 into dispatch harm |
| Heartbeat SLO (VV-505) unmeetable on target platforms | Block launch; the dead-man's switch is unreliable (Blueprint risk #4) — D11's backstop must be real before anyone depends on it |
| Daily drill (VV-301) cannot run reliably | Block launch; an unobservable pipeline violates D20 — we would not know when we broke |
| Any red Validation Assumption (VA) with no mitigation path | Block dependent releases until re-established or formally re-scoped by RFC |

*Stopping is a decision, not a failure: each trigger routes to a named fallback (redesign, re-tier, human-in-loop, RFC) — never to quiet target-loosening (D20; the C12 threshold-drift lesson applied to ourselves).*

---

## Architecture Stability Gate (the final checkpoint: `Architecture Review → Implementation Approval → Code`)

Before the first production line of each phase — and comprehensively before Phase S — every box must be **Yes**:

- [ ] Every foundational ADR (001–015) and detailed ADR (101–112) has an implementing subsystem and no open contradiction
- [ ] Every interface (12) has a named producer, consumer, contract version, and failure semantics — none orphaned
- [ ] Every subsystem (08A) has an owner (Part C) — including its **Never Owns** boundary
- [ ] Every hazard (10A) has implemented controls (10B) with live VV coverage — `No`-observable hazards have *fresh* manufactured evidence
- [ ] Every VV gate for the phase is PASS (not BLOCKED, not NOT-EXECUTED)
- [ ] No unresolved RFCs against the frozen foundation (00A)
- [ ] Technical Debt Register (Part D) has no expired "remove before" row
- [ ] Validation Assumptions Register (13) has no red row

**Any "No" → implementation does not begin.** The gate is re-run at every field-phase transition.

---

## Definition of Engineering Ready (the one page)

> **RAXHA is Engineering Ready when:**
> every architectural decision is traceable to doctrine and product intent (D## → ADR → Blueprint);
> every safety hazard has an implemented, verified control (10A → 10B → VV);
> every interface has a versioned contract with declared failure semantics (12);
> every requirement has a verification method, and every verification produces archived evidence (09 → 13);
> every unobservable failure mode has manufactured evidence — drills, replay, shadow — inside its validity window (D20);
> every assumption underlying validation is registered, monitored, and green (VA);
> every accepted shortcut carries its expiry (Part D);
> every kill criterion is armed and honored (Part E);
> and the Architecture Stability Gate answers Yes on every line.
>
> **This is the engineering equivalent of the Academy's "Competency Passed" — and it is the only sentence that authorizes `implementation/` to stop being empty.**

---

*The engineering document set (00A–14) is COMPLETE. From here forward: RFCs for genuine architecture change, revisions to existing artifacts, implementation, and evidence from testing and operation. No new foundational document types.*
