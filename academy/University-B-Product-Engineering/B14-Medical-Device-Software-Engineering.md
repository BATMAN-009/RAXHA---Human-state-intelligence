# Chapter B14 — Medical-Device Software Engineering & Regulatory Quality

> **Paired with:** Competency 15 (Medical AI, Clinical Validation & Regulatory). That chapter defined *what RAXHA may claim*; this one is the engineering discipline that makes a claim *defensible in code* — the lifecycle, quality system, traceability, and verification that turn "we validated it" from an assertion into an auditable record. When RAXHA pursues a cleared claim, the difference between a submission that clears and one that doesn't is largely *this* chapter. The good news: RAXHA's architecture (pure core, replay CI, governed deploys, observability) already embodies most of it — this chapter names the regulatory form of what you've built. The finale of the Engineering track's core arc.

---

## 1. Why medical-device software engineering is different

Ordinary software optimizes for velocity; medical-device software optimizes for **demonstrable safety and traceability**. The distinguishing demand: you must *prove*, with documented evidence, that every requirement traces to a design element, to code, to a test, and to a risk control — and that the whole thing was built under a controlled process. A regulator doesn't accept "it works"; they accept "here is the auditable chain showing why it works and what happens when it doesn't." For RAXHA, this is the engineering counterpart to the Confidence Ledger: *evidence, traceable, for every claim.*

---

## 2. The standards, and what each demands

- **IEC 62304 (software lifecycle):** the core standard. Requires a defined software development process, **software safety classification** (Class A/B/C by injury potential — RAXHA's safety path is Class C: death/serious-injury possible if it fails), architecture and detailed design records, unit/integration/system verification, **traceability** (requirement → design → code → test), configuration management, and a defined process for **SOUP** ("Software Of Unknown Provenance" — third-party/open-source components; you must justify and risk-assess each).
- **ISO 14971 (risk management):** the medical FMEA — systematically identify hazards, estimate risk (severity × probability), implement risk controls, verify them, and evaluate residual risk. RAXHA's failure-analysis tables (§14 of every chapter) are proto-ISO-14971; this formalizes them into a risk-management file.
- **ISO 13485 (QMS):** the quality management system — document control, design controls, CAPA (Corrective And Preventive Action), management responsibility. The *organizational* discipline around the engineering.
- **Design Controls (FDA 21 CFR 820.30):** design inputs (requirements) → design outputs (the built system) → verification (built it right) → validation (built the right thing) → design review → design history file (DHF). The V3 framework (C14) lives inside this.
- **IEC 62443 / FDA cybersecurity guidance:** security (B11) is now a *submission requirement* — threat modeling, SBOM (software bill of materials), vulnerability management, as regulatory deliverables.

## 3. Traceability — the spine of a defensible system

The single most important regulatory-engineering artifact is the **traceability matrix**:
```
Requirement  →  Risk (ISO 14971)  →  Design element  →  Code  →  Verification test  →  Validation evidence
"Detect fall     "Missed fall →      EscalationFSM +    core/    replay-harness       clinical study /
 within 90s"      death (Class C)"    fall cascade      fsm/     assertion            real-world eval
```
Every safety requirement must trace end-to-end. RAXHA's advantages here are *structural*: the pure domain core (B13) makes requirements map cleanly to design elements; the replay harness (B12) *is* the verification evidence, automated; DDD's ubiquitous language (B13) means the requirement, the code, and the test all speak the same terms. **A clean hexagonal architecture is also a clean traceability story** — the regulatory payoff of the discipline you already have.

## 4. Verification vs Validation (the regulatory meanings)

- **Verification:** "did we build the system right?" — does it meet its specified requirements? (Unit tests, integration tests, the replay harness asserting spec compliance — B12.)
- **Validation:** "did we build the right system?" — does it meet the *user/clinical need* in the real world? (Clinical validation, V3's third axis, RCT — C14/C15.)
This is the same V/V split as C14's V3, now as a regulatory lifecycle requirement with documented evidence for each.

## 5. The lifecycle for AI/ML (the hard, evolving part)

Classical IEC 62304 assumes *locked* software. RAXHA's models *learn* (C13 federated, B12 shadow-retrained). The reconciliation:
- **Locked-model submission:** validate and freeze a specific model version — simplest, but forfeits continuous improvement.
- **PCCP (Predetermined Change Control Plan, C15):** pre-specify the *protocol* by which models may update (retraining data, validation gates, performance bounds, rollback) — FDA pre-authorizes the *process*, so in-scope updates don't each need a new submission. RAXHA's governed-deploy pipeline (B8/B9/B12 — signed, canaried, shadow-tested, rollback-able, with two-sided metrics) is *exactly* the machinery a PCCP requires. **RAXHA's MLOps discipline is its PCCP in embryo.**
- **Model documentation:** training data provenance + representativeness (the C13 fairness/equity metrics), performance by subgroup, calibration (Decision #18), intended use — the "model card" as regulatory record.

## 6. RAXHA production shape (regulatory engineering)

- **Design History File (DHF):** requirements, risk file (ISO 14971), architecture (B13), traceability matrix, V&V records (B12), design reviews — assembled *as you build*, not retrofitted.
- **Risk-management file:** the failure-analysis tables across all chapters, formalized into hazards → controls → residual-risk evaluation.
- **Automated evidence:** the replay harness, chaos suite, drills, calibration + two-sided monitoring (B12) generate *verification and post-market evidence continuously* — CI produces the regulatory record as a byproduct.
- **Governed deploys as change control:** signed/canaried/shadow-tested/rollback (B8/B9) = the PCCP mechanism; threshold changes governed as safety artifacts (Decision #20) = design change control.
- **SBOM + threat model (B11):** the cybersecurity submission deliverables.
- **QMS from day one:** document control, CAPA, design reviews — lightweight early, but *present*, because retrofitting a QMS onto years of ungoverned work is often infeasible.

## 7. Founder Intelligence

**Strategic reading:** regulatory-engineering discipline is a *moat and a barrier to entry* — it's slow, expensive, and cultural, so a competitor can't shortcut it, and RAXHA's early adoption (QMS + traceability + governed ML from the start) compounds into a clearable-claim capability others lack. **The convergence payoff:** RAXHA's *good engineering* (pure core, replay CI, governed deploys, observability, Confidence Ledger) is *already* ~70% of the regulatory evidence machine — the discipline that makes the software good makes it *clearable*. **The PCCP frontier:** whoever operationalizes PCCP-governed continuously-improving models well has a durable advantage in AI medical devices — RAXHA's MLOps is the foundation. **Ledger:** ✅ standards (IEC 62304/ISO 14971/13485), design controls, FDA cybersecurity/PCCP guidance (all public); 🟡 optimal AI-lifecycle practice (evolving); 🔴 competitors' internal QMS maturity. **Kill-relevant:** if the team treats QMS/traceability as "later," the cleared-claim path closes (unretrofittable) — regulatory engineering is a *day-one* organizational choice, not a pre-submission sprint.

## 8. Design Review (highlights)

- **Regulatory/QA lead:** "Show me the traceability matrix: every Class-C requirement → risk → design → code → test → validation. Gaps are non-clearable."
- **FDA reviewer:** "Your risk-management file (ISO 14971), your software lifecycle (IEC 62304 Class C), your V&V records, your PCCP for the models, your cybersecurity (SBOM + threat model). Assembled contemporaneously, not reconstructed."
- **Principal engineer:** "The pure core + replay CI + governed deploys *are* the evidence engine. Confirm CI emits the verification record automatically."
- **SRE:** "Post-market surveillance = your fleet observability (B12). Adverse-event detection, drift, real-world performance — as a regulatory duty."

## 9. Constraint Exercise

Map RAXHA's *existing* engineering (from B1–B13) onto a medical-device-software compliance framework for a future Class-C fall-detection clearance. Constraints: IEC 62304 Class C, ISO 14971 risk file, design controls + DHF, traceability end-to-end, a PCCP for the updating models, cybersecurity deliverables, and QMS-from-day-one. Specify: which existing artifacts (pure core, replay harness, failure tables, governed deploys, Confidence Ledger, observability) satisfy which regulatory requirement, what's *missing* and must be added, and the day-one QMS-lite you'd stand up so the cleared-claim path stays open. One-page mapping.

## 10. Chief Scientist's Verdict

**Confidence Ledger:** IEC 62304 / ISO 14971 / 13485 / design controls as the defensible-claim foundation — ★★★★★ (established, required). RAXHA's architecture already satisfying most of it — ★★★★☆ (strong; traceability + QMS formalization needed). PCCP as the path for updating models — ★★★☆☆ (emerging but real). "Good engineering ≈ regulatory evidence engine" — ★★★★☆.
**TRL:** The standards/processes — 9 (mature). RAXHA's compliance-readiness — 5–6 (architecture ready; QMS/traceability/DHF to formalize). PCCP-governed ML lifecycle — 5–6.
**Roadmap:** *Now:* QMS-lite + risk file + traceability discipline from day one; CI-as-evidence. *V2 (pre-submission):* full DHF, formal V&V, PCCP, cybersecurity deliverables. *V3:* submission + post-market surveillance. *Never Build:* a cleared-claim ambition without day-one QMS/traceability (unretrofittable); ML medical features without a change-control plan.
**Competitor failures (sourced):** medical-device software recalls traced to inadequate lifecycle/traceability (documented across the industry — the reason IEC 62304 exists). Digital-health startups that pursued clearance late and stalled because the engineering wasn't traceable/documented. Contrast: rigorous-from-the-start medical-device companies (Dexcom-class) whose discipline enabled clearance and iteration.
**Kill Criteria:** if QMS/traceability isn't sustained from day one, defer the cleared-claim ambition rather than fake a retrofit (regulators detect reconstructed records). If the ML lifecycle can't fit a PCCP, submit locked models or don't submit. If cybersecurity deliverables can't be produced, the connected-device submission fails — B11 is non-optional.
**Historical Failures (Historian):** medical-device-software recalls from lifecycle/traceability gaps (why the standards exist). Late-regulatory digital-health startups that couldn't reconstruct the evidence chain. The meta-lesson mirrors C15: *the discipline that makes safety-critical software good is the same discipline that makes it clearable — and both must start on day one.*

## 11. Knowledge Graph Connections

- **Depends on (prior):** C15 (the claims + clinical strategy this makes real), B12 (V&V + post-market = automated regulatory evidence), B13 (architecture = traceability), B11 (cybersecurity deliverables), B8/B9 (governed deploys = PCCP mechanism), Decisions #7 (architecture-before-code), #16 (evidence), #20 (threshold change control).
- **Depended on by (future):** any cleared-claim submission; the Institute of Clinical & Safety Sciences (E); the company's regulatory capability.
- **RAXHA subsystem:** the regulatory-engineering + quality layer wrapping all software; the bridge from "built" to "clearable."
- **AI models:** governed under PCCP; documented (model cards, subgroup performance, calibration, provenance).
- **Sensors contributing:** none directly; every sensor-derived safety function inherits the lifecycle + risk discipline.
- **Assumptions for validity:** QMS/traceability from day one; IEC 62304 Class C rigor; ISO 14971 risk file; PCCP for ML; cybersecurity deliverables; contemporaneous (not reconstructed) records.
- **Confidence:** standards + RAXHA-architecture-fit ★★★★ / PCCP ML lifecycle ★★★. See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*This closes the ENGINEERING track's core arc. Remaining B-chapters (B15 event-driven backend deep-dive, B16 auth/encryption deep-dive) fold into the Institutes as needed. The core arc (Competencies 1–15, both tracks) is complete upon passing the Competency-15 gate.*
