# RAXHA Academy — Five-University Expansion Plan

> **Status:** SPEC CAPTURED (user-directed, 2026-07-13). **Queued as AQ-4** — ratifies on the Competency-13 gate pass, then builds via the normal gated progression (NOT bulk-generated). This preserves the vision without perpetually re-architecting an unfinished curriculum (the Structural Freeze, Doctrine Amendment 2).
>
> **Rationale (user's, endorsed):** to compete with Apple/Google/Garmin/WHOOP/Life360/Dexcom/Empatica over 10–20 years, RAXHA's founder needs medicine, human behavior, systems engineering, business strategy, and competitive intelligence integrated with the science and engineering already covered. Current curriculum ≈ 75–80% of a world-class education; this is the remaining 20–25%.

---

## The five Institutes (✅ AQ-4 RATIFIED 2026-07-13, Competency-13 gate)

> Named by **mission**, not discipline (adopted from the Competency-13 gate) — names communicate purpose, not org buckets.

| Institute (was) | Mission | Scope | Status |
|---|---|---|---|
| **Institute of Human State Science** (A) | *Understand the human body and everything measurable about it.* | Sensors, physiology, biomechanics, signal processing, biomarkers, gait, HAR, fusion | ✅ EXISTS (C1–13 science) |
| **Institute of Intelligent Systems Engineering** (B) | *Build reliable software that never fails when lives depend on it.* | Native dev, backend, distributed systems, security, testing, ML deployment, observability | ✅ EXISTS (B1–B12 + B13–16) |
| **Institute of Human Behavior & Society** (C) | *Understand how humans actually behave — not how engineers think they behave.* | Psychology, behavioral economics, caregiver behavior, sociology, trust, product strategy | 🆕 build after core arc |
| **Institute of Intelligence Research** (D) | *Learn from the world's best companies and the frontier of research.* | Company intelligence, patents, papers, reverse engineering, AI research, experimental design | 🆕 build after core arc |
| **Institute of Clinical & Safety Sciences** (E) | *Prove that RAXHA deserves to exist.* | Emergency medicine, clinical reasoning, epidemiology, reliability engineering, systems engineering, FDA/IEC/ISO | 🆕 build after core arc |

**Institute of Leadership (6th)** — queued as AQ-6; built *after* the five, once RAXHA hires teams. *Purpose: the limiting factor eventually becomes leadership quality, not technical knowledge.* Hiring, research culture, technical decision-making, incident command, capital allocation, investor comms, ethics, company philosophy, architecture reviews, org scaling.

Mirrors how Apple/Google/Medtronic/Garmin/WHOOP organize expertise internally.

---

## New domains — mapped to existing SEEDS (what's genuinely new vs. needs consolidation)

**Honest accounting: many "missing" domains are already seeded across Competencies 1–13. The expansion is more "consolidate + deepen + add the truly new" than "start from zero."**

| Domain (user-requested) | University | Existing seeds in the KB | Work needed |
|---|---|---|---|
| **Deep human physiology** (cardiovascular, respiratory, autonomic, endocrine, sleep, aging, pediatric, female, exercise) | E | HRV/ANS (C5), respiration (1.12 planned), biomechanics (C8 gait), cardiac (PPG/ECG) | **Mostly new** — dedicated competencies; the "82-yr-old fall → internal bleed reasoning" clinical-reasoning thread |
| **Psychology** (trust, alarm fatigue, panic, decision-under-stress, notification design, grief, caregiver behavior) | C | Alarm fatigue (medical §12s, Decision #19), trust budget (#19), human factors (manifesto L14) | **Mostly new** — genuinely underdeveloped, high-value |
| **Sociology** (families, aging populations, loneliness, caregiving, cultural emergency-response differences) | C | Family-response framing, elder-care B2B | **New** |
| **Modern AI research** (transformers, representation/contrastive/self-supervised learning, foundation models, time-series transformers, diffusion, GNNs, world models, causal inference) | D | SSL/transformers/DeepConvLSTM (C9 HAR §8/10), foundation-model-for-motion (C9/C11) | **Partial → deepen** for AI-team leadership |
| **Time-series science** (Fourier, wavelets, spectrograms, Hilbert, state-space, HMM, Bayesian/particle filters, sequential hypothesis testing, CUSUM, change-point, online/streaming stats) | A/E | Filters (C10 fusion), CUSUM/EWMA/change-point (C11), spectral (1.8/C9), Module 2 Math + Module 3 Signal Processing (planned, not yet written) | **Consolidate** — Modules 2–3 were always planned; write them |
| **Reliability engineering** (FMEA, STPA, fault trees, RBD, MTBF, redundancy, Byzantine, formal verification, chaos, safety cases) | E | Chaos/replay/drills (B12), FMEA (doctrine §6 doc set), dead-man's switch/redundancy (#11) | **Partial → deepen** into a dedicated competency |
| **Systems engineering** (requirements, traceability, V&V, interface control, config mgmt, trade studies) | E | Architecture-doc set (doctrine §6), API contracts | **New** — dedicated treatment |
| **Product economics** (CAC, LTV, retention, pricing, reimbursement, enterprise/hospital sales, B2B2C) | C | Life360 comparable, B2B facility wedge (1.7), moat analyses (§18s) | **New** |
| **Behavioral economics** (loss aversion, prospect theory, nudging, trust economics, when people buy safety, churn) | C | Trust budget (#19), alarm fatigue | **New** |
| **Epidemiology** (sensitivity, specificity, PPV, NPV, Bayesian prevalence, screening, bias, confounding, RCTs, external validity) | E | Base-rate trap (C1 — literally epidemiology), sens/spec (medical §12s), FARSEEING external-validity | **Consolidate** — threaded everywhere, deserves formal chapter |
| **Company Intelligence** (deep reverse-engineering) | D | §18 Founder Intelligence + ✅/🟡/🔴 ledgers per chapter | **Deepen substantially** — see below |

---

## Company Intelligence module (D) — the deep reverse-engineering spec

> **User's explicit instruction (2026-07-13):** "each company i mentioned reverse engineer and study should go deeply more deep clearly." The per-chapter §18 ledgers are *thin slices*; this module is the *deep, dedicated* study.

**Companies to study (each a full deep-dive):**
Apple · Google · Garmin · WHOOP · Oura · Fitbit · Dexcom · Abbott · Life360 · Empatica · AliveCor · Biofourmis · Samsung · Huawei · Polar · Zepp · Withings · (+ future entrants)

**Deep-dive template (per company):**
1. Origin story & founding thesis
2. Technology evolution (timeline)
3. Patent portfolio (themes + assignees + Google Patents queries — Patent Rigor Rule; verified numbers only)
4. Acquisitions (what they bought and why)
5. Key research papers / publications
6. System architecture (inferred, ✅/🟡/🔴 labeled)
7. Pivotal product decisions
8. Documented failures & recalls
9. Regulatory history (FDA clearances, CE, actions)
10. Business model & unit economics
11. Competitive moat (what's actually defensible)
12. Organizational structure (how they organize expertise)
13. **What RAXHA learns / must beat / must avoid** (the synthesis)

**Rigor:** every claim ✅ documented / 🟡 strong inference / 🔴 unknown (existing ledger discipline). "Living competitive intelligence" — updated as companies move.

---

## Sequencing (proposed — confirm on ratification)

Finish the **core arc first** (Competencies 14–15: Digital Biomarkers, then Medical/Clinical/Regulatory) — this completes University A/B and the original RAXHA-build spine. **Then** open Universities C, D, E as the "founder-scale" phase. Rationale: the core arc makes RAXHA *buildable*; C/D/E make the founder able to *lead a company that competes for 20 years*. Don't interleave so heavily that the buildable core never closes.

**Governing mission (unchanged, now broad enough to guide all five universities):**
> RAXHA is not building a better fall detector. It is building a trustworthy **Human State Intelligence System** that transforms uncertain physiological, behavioral, and contextual evidence into the most appropriate human response, while preserving privacy by design and maintaining calibrated trust over years of use.
