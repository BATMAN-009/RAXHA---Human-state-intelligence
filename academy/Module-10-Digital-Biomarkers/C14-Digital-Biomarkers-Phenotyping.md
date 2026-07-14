# Competency 14 (Science) — Digital Biomarkers & Digital Phenotyping

> **Why this is the convergence competency.** Every signal you've studied — HR, HRV, gait, activity, sleep, mobility, location routine — has been treated as an *input to a moment's decision*. This competency reframes them as **longitudinal biomarkers**: the continuous, passive, in-the-wild measurement of a person's health and behavior over months and years. Individually they're sensors; together, over time, they form a **digital phenotype** — a quantified signature of *who this person is when healthy*, precise enough that its slow deformation reveals disease, decline, and recovery before the person notices. This is the layer that turns RAXHA from an emergency-response system into a *health-trajectory* system, and it's the scientific foundation of the personal baseline (Decision #16) at its richest.

---

## 1. Definition

- **Biomarker:** an objective, measurable indicator of a biological state or condition (blood glucose, blood pressure, a genetic variant).
- **Digital biomarker:** a biomarker derived from *digital devices* — sensors on a wearable/phone — often measuring things no lab test can capture continuously and in daily life (gait variability, nightly HRV, mobility patterns, sleep architecture).
- **Digital phenotyping** (Jain, Onnela et al., ~2015): "moment-by-moment quantification of the individual-level human phenotype in situ using data from personal digital devices" — the *whole behavioral/physiological signature*, active (surveys, tests) + passive (sensors), assembled into a longitudinal portrait.

The conceptual ladder of the whole curriculum, completed:
- A **signal** (Ch 1.1–1.10): what a sensor reads now.
- A **state estimate** (C10): the fused, calibrated present.
- A **baseline** (C5/C8/C11): this person's normal.
- A **digital biomarker** (here): a validated, longitudinal indicator derived from all of the above.
- A **digital phenotype** (here): the person's full quantified health-behavior signature over time.

---

## 2. History

Biomarkers are old (temperature, pulse, blood tests). **Actigraphy** (accelerometer-based activity/sleep monitoring) has clinical roots from the 1970s–80s. The *digital* biomarker era began when wearables put continuous sensing on millions of wrists (2010s) and researchers realized the *passive, longitudinal, in-the-wild* data captured things clinic snapshots miss. **Digital phenotyping** was named and formalized ~2015 (Onnela, Harvard — especially in psychiatry: smartphone mobility/social/typing patterns as mental-health signals). The **Digital Medicine Society (DiMe)** and FDA have since built frameworks for *validating* digital biomarkers (the V3 framework, §3.3) — the field's maturation from "interesting sensor data" to "regulated clinical measure."

---

## 3. Scientific Foundation

### 3.1 Types of digital biomarker
- **Physiological:** HR, HRV, SpO₂, respiration, skin temperature, blood-pressure estimates (Ch 1.8–1.15).
- **Behavioral:** activity/energy expenditure, gait (C8), sleep architecture and timing, mobility (how far/where you go), social patterns (call/text metadata in phenotyping), device-interaction patterns.
- **Passive vs active:** passive (collected without user effort — the wearable's advantage) vs active (a prompted test — a 6-minute-walk, a cognitive tap-test). RAXHA is overwhelmingly *passive*, which is its structural strength (no compliance burden) and its limitation (less controlled).

### 3.2 Why longitudinal + passive + in-the-wild is a paradigm shift
A clinic measures gait speed *once a year, in a hallway, when the patient is trying*. RAXHA measures it *continuously, in real life, unobserved* — capturing trends, variability, and context a snapshot cannot. This is genuinely new clinical information: **the trajectory and its day-to-day variability often carry more signal than any single value** (the HRV/gait-variability lesson, C5/C8, generalized). Digital biomarkers see *change over time in natural conditions* — exactly what Decision #16 ("classify changes, not people") needs.

### 3.3 Validation — the V3 framework (this is what separates a biomarker from a number)
A digital biomarker is only trustworthy if validated across three axes (DiMe/FDA V3):
1. **Verification:** does the *sensor/hardware* measure the raw signal accurately? (Is the accelerometer's output correct? — Ch 1.1.)
2. **Analytical validation:** does the *algorithm* correctly compute the metric from the signal? (Does your gait-speed algorithm match a gold-standard gait lab?)
3. **Clinical validation:** does the metric *actually relate to the clinical outcome* it claims? (Does your gait-variability biomarker actually predict falls *in the target population*?)
Skipping any is how you ship a ★★-evidence biomarker with ★★★★★ marketing. RAXHA's Confidence Ledger (§21) is V3 discipline made habitual. **This framework is also the bridge to Competency 15 (regulatory)** — FDA biomarker qualification *is* V3, formalized.

### 3.4 The digital twin (the endpoint)
Fuse all a person's digital biomarkers over time and you approach a **digital twin**: a personalized, continuously-updated model of their health-behavior that can (aspirationally) simulate "what's normal for them" and flag deviation, or even forecast trajectory. Today this is partial and mostly baseline-modeling (not true simulation); it's the horizon the personal-baseline engine (C5/C11) is walking toward.

---

## 4–8. Working, Data, Algorithms (RAXHA-specific)

**The biomarker layer sits above fusion and baselines:**
```
fused state (C10) + personal baselines (C5/C8/C11), over MONTHS
  → digital biomarkers (validated longitudinal metrics: gait speed/variability, nightly HRV,
       resting HR trend, sleep architecture, mobility/activity, location-routine entropy)
  → the digital phenotype (the person's health-behavior signature over time)
  → trajectory analysis (trend, variability, change-point) → decline / illness / recovery signals
  → feeds Anomaly Detection (C11) + Risk Scoring (C12) with RICH personal context
```

**What RAXHA's biomarkers reveal (as *observation*, per screening-not-diagnosis):** rising fall-risk (gait decline, C8), illness onset (resting-HR up + HRV down, C10 §10), mobility decline (aging, disease), sleep deterioration, recovery progress (positive framing), and — with phenotyping — behavioral changes (reduced mobility/social patterns) associated with depression/cognitive decline (★★–★★★, an active research frontier, handle with great care).

**Mobility metrics worth naming** (validated, wearable-derivable): **life-space** (how large an area you move through), activity fragmentation, sedentary-bout patterns, gait-speed trend, "walking steadiness" (Apple ships this, C8). Declining life-space and gait speed are among the strongest wearable-derivable frailty/decline signals.

**Algorithms:** trend + variability + change-point on each biomarker (C11's machinery); multivariate phenotype modeling; the personal baseline as the reference (Decision #16); validation against clinical ground truth (V3).

## 9–12. Products, Research, Security, Medical (brief)

**Products:** Apple (Walking Steadiness, Cardio Fitness/VO₂max trend, sleep, Mobility metrics — the clearest shipped digital-biomarker suite, ✅), Fitbit/Google (readiness, sleep, health metrics), WHOOP/Oura (recovery/strain/readiness as composite digital biomarkers), **Dexcom/Abbott** (continuous glucose — the *gold-standard* validated continuous digital biomarker, a model for rigor), Biofourmis (clinical digital-biomarker platform). **Research:** Onnela (digital phenotyping); DiMe V3 framework; wearable illness-prediction (Mishra 2020); gait/mobility as frailty biomarkers (Studenski lineage); mental-health phenotyping. **Open problems:** rigorous clinical validation at scale, phenotyping's clinical actionability, generalization/equity, and *actionability* (a biomarker that predicts but can't guide action is limited). **Security:** the digital phenotype is the *most complete and intimate* dataset a person emits — the ultimate case for on-device/federated/minimization (C13, B11); a leaked phenotype reveals health, behavior, and identity. **Medical:** digital biomarkers are increasingly FDA-recognized *when validated*; the screening/diagnosis line and V3 are everything; over-claiming here is both a scientific and regulatory failure (Competency 15).

## 13. Engineering for RAXHA

1. **Build the biomarker layer as durable, longitudinal infrastructure** — the personal-baseline engine (C5/C11) matured into a validated, trended, multi-biomarker health portrait, stored as the system-of-record health data (B4), personalized and privacy-preserved (C13/B11).
2. **V3 discipline on every biomarker** (verification → analytical → clinical validation): ship as *observation* until clinically validated on the target population; label confidence (§21).
3. **Trajectory > snapshot:** trend, variability, change-point are the signal (Decision #16).
4. **Feeds anomaly + risk richly** (C11/C12): a good phenotype makes "change from baseline" precise and context-aware.
5. **Fall-*risk*/decline as the flagship biomarker application** (C8) — the prevention value-prop.
6. **Privacy is paramount** — the phenotype is the crown-jewel sensitive asset; on-device/federated, minimized, E2E (C13/B11).
7. **Honesty about phenotyping's frontier** — mental-health/cognitive inferences are ★★–★★★; observation not diagnosis, great care, consent.

## 14. Failure Analysis

| Failure | Mechanism | Mitigation |
|---|---|---|
| Unvalidated biomarker over-claimed | Skipped V3 (esp. clinical) | Full V3; ship as observation until validated; label confidence |
| Snapshot misleads | Single value vs trajectory | Trend/variability/change-point (Decision #16) |
| Wrist coarseness overstated as clinical | Wrist ≠ gait lab (C8) | Report relative trends; validate before absolute claims |
| Phenotype leak = catastrophic exposure | Centralized intimate data | On-device/federated/E2E/minimization (C13/B11) |
| Inequitable biomarker | Validated on narrow population | Diverse validation (the equity thread: C4 skin-tone, C13 FL-fairness) |
| Mental-health over-inference | ★★ claim as certainty | Great care; observation; consent; frontier honesty |
| Predicts but not actionable | Biomarker without intervention path | Pair biomarkers with actionable observation/guidance |

## 15. RAXHA Application — distilled

- **Use as:** the longitudinal health-intelligence layer — the rich personal phenotype that makes anomaly detection and risk scoring see decline coming (prevention), and the foundation of RAXHA's expansion from "emergency response" to "human-state trajectory."
- **Do NOT use as:** an unvalidated diagnostic; a snapshot judge; a centralized phenotype database; a source of confident mental-health/cognitive inference.
- **One-liner:** *digital biomarkers are how RAXHA stops asking "is this person in trouble right now?" and starts asking "where is this person's health heading?" — the shift from rescue to foresight, on a scale of years.*

## 16. Future

Validated wearable clinical biomarkers at scale; the maturing digital twin (baseline → forecast → simulate); multimodal phenotyping (physiology + behavior + context); FDA-qualified digital biomarkers as endpoints (pharma trials, care); federated phenotype learning (C13); the convergence of biomarkers + anomaly + risk into one continuous personalized health-trajectory model — RAXHA's long-term scientific core.

## 17. Mastery Test — Competency 14

1. Distinguish signal → state → baseline → digital biomarker → digital phenotype. What does each add?
2. Why is passive, longitudinal, in-the-wild measurement a *paradigm shift* over clinic snapshots — and what new clinical information does it capture?
3. State the V3 framework (verification / analytical / clinical validation). Why is skipping clinical validation the classic ★★-evidence/★★★★★-marketing failure?
4. Why is the digital phenotype simultaneously RAXHA's richest asset and its gravest privacy responsibility (tie to C13/B11)?
5. How do digital biomarkers operationalize Decision #16 at the scale of years, and how do they feed Anomaly Detection and Risk Scoring?
6. Why must digital biomarkers be validated on *diverse* populations (tie to the equity thread: C4, C13)?
7. **[Standing gate question]** If RAXHA shipped digital-biomarker health-trajectory features tomorrow, what's the single most likely field failure — scientific, platform, or product?

## 18. Founder Intelligence

**Why hasn't this been "solved"?** Rigorous clinical validation (V3) at scale is slow and expensive; wrist signals are coarse; actionability is hard; and phenotyping's clinical value (esp. mental health) is still being proven. Apple ships validated biomarkers conservatively (Walking Steadiness, Cardio Fitness); **Dexcom/Abbott** show the gold standard — a *rigorously validated* continuous biomarker (glucose) that became a multi-billion-dollar category. **WHOOP/Oura** productize composite biomarkers (recovery/readiness) as consumer wellness (less clinical validation, more engagement). **Biofourmis** productizes clinical digital biomarkers for healthcare. **The moat:** a *validated, longitudinal, multimodal phenotype* per user is the deepest personalization+data asset in the space — it compounds with tenure (Decision #16) and, once clinically validated, unlocks regulated/reimbursed markets (the Dexcom path). **Why doesn't everyone?** validation cost, the actionability gap, and privacy sensitivity. **Startup opportunities:** validated fall-risk/frailty biomarkers for elder care + insurers (reimbursement), decline/illness pre-warning, rehab-progress biomarkers, digital biomarkers as pharma-trial endpoints (a large B2B market), phenotype-as-infrastructure. **RAXHA strategy:** the biomarker layer is the expansion from *safety* to *health trajectory* — the path from consumer safety app to clinically-serious platform (and to reimbursed/regulated markets, Competency 15). Build V3-validated, privacy-preserved, observation-framed; pursue clinical validation deliberately for specific claims. **PhD gaps:** validated wearable clinical biomarkers, actionable phenotyping, equitable validation, the digital-twin forecast. **Patents:** biomarker/mobility-metric families (Apple/Dexcom/Biofourmis — query `digital biomarker gait mobility assignee:X`); CGM (Dexcom/Abbott). **Ledger:** ✅ shipped biomarkers, V3 framework, CGM as gold standard; 🟡 vendor phenotype models; 🔴 unvalidated-claim internals.

## 19. Design Review (highlights)

- **Physician:** "A continuous, in-the-wild gait-speed and life-space trend is genuinely useful to me — *if* it's V3-validated on my population and framed as observation. The trajectory is the clinical value. Don't hand me an unvalidated 'digital twin.'"
- **Chief Scientist:** "Every biomarker: show me verification, analytical, AND clinical validation. Clinical is the one everyone skips and the only one that makes it a biomarker."
- **Privacy advocate:** "The phenotype is the most complete profile of a human you'll ever hold. On-device/federated/E2E/minimized — the crown-jewel case for C13/B11."
- **Investor:** "Dexcom proved a validated continuous biomarker is a category. Your fall-risk/frailty phenotype could be the same for elder care + insurers. What's the validation + reimbursement path?"
- **Regulator (Competency 15):** "A validated digital biomarker can be a regulated measure. V3 is your evidence. Claims must match it."
- **Ethicist:** "Mental-health/cognitive phenotyping is powerful and dangerous. Consent, observation-not-diagnosis, and equity are non-negotiable."

## 20. Constraint Exercise

Design RAXHA's fall-risk/frailty digital-biomarker for an elder-care + insurer deployment. Constraints: wrist-coarse signals, full V3 validation required before any clinical claim, diverse/equitable validation, trajectory-based (not snapshot), on-device/federated privacy, observation-not-diagnosis framing, and an actionable output (not just a prediction). Specify: the biomarkers (gait speed/variability, life-space, HRV, activity), the V3 validation plan, the trajectory model, the equity plan, the privacy design, and the exact caregiver/insurer-facing output + language. One-page memo.

## 21. Chief Scientist's Verdict

**Confidence Ledger:** Wearable digital biomarkers (gait speed, HRV, activity, sleep) as valid health indicators — ★★★★☆ (many validated; wrist-coarseness caveats). Gait/mobility as frailty/fall-risk biomarkers — ★★★★☆. CGM as gold-standard validated continuous biomarker — ★★★★★. Digital phenotyping for mental health — ★★★☆☆ (frontier, promising). The "digital twin" (forecast/simulate) — ★★☆☆☆ (aspirational; today = baseline modeling). Passive longitudinal > snapshot — ★★★★★.
**TRL:** Shipped consumer biomarkers (steadiness, cardio fitness, sleep) — 8–9. CGM — 9. Validated wearable fall-risk/frailty biomarker — 5–6. Digital phenotyping (mental health) — 4–5. Digital twin — 2–3.
**Roadmap:** *MVP:* longitudinal personal-baseline biomarkers (HR/HRV/gait/activity/mobility trends) as observation. *V2:* V3-validated fall-risk/frailty biomarker, illness pre-warning, elder-care/insurer product. *Research:* phenotyping, digital twin, clinical-endpoint validation. *Never Build:* unvalidated biomarkers with clinical claims; centralized phenotype DB; confident mental-health diagnosis; snapshot-only judgments.
**Competitor failures (sourced):** consumer wellness metrics (recovery/readiness/sleep-staging) criticized for weak clinical validation vs their implied authority (the V3-clinical-skip pattern). Digital-phenotyping mental-health overclaims ahead of validation (documented skepticism). The recurring lab-vs-life generalization gap. Contrast the *success*: CGM's rigorous validation → regulated, reimbursed, trusted — the model to emulate.
**Kill Criteria:** if a biomarker can't pass clinical validation (V3) on the target population, it ships as wellness observation only, never a clinical claim. If validation isn't equitable across the served population, it doesn't launch for the underserved group until fixed. If the phenotype can't be privacy-preserved (on-device/federated), minimize what's built rather than centralize intimate data.
**Historical Failures (Historian):** consumer health-metric overclaims (wellness marketed as clinical without V3). Digital-phenotyping hype cycles (powerful idea, slow clinical proof). The broader "quantified self" wave (rich data, thin validated clinical value) — the lesson RAXHA encodes via V3. Contrast: CGM/Dexcom as the rigor-wins success story the Historian holds up as the model.

## 22. Knowledge Graph Connections

- **Depends on (prior):** C5 HR/HRV baseline, C8 gait, C9 HAR, C10 fusion, C11 anomaly/baseline (the machinery), B4 health store, C13/B11 privacy, Decisions #16/#18/#21.
- **Depended on by (future):** Competency 15 (clinical validation/regulatory — V3 is the bridge); Anomaly Detection (C11) and Risk Scoring (C12) consume the richer phenotype; the digital-twin future.
- **RAXHA subsystem:** the longitudinal health-intelligence layer / personal-phenotype engine; feeds anomaly + risk; the safety→health-trajectory expansion.
- **AI models:** trend/variability/change-point per biomarker; multivariate phenotype models; personal-baseline (Decision #16); validated against clinical ground truth (V3).
- **Sensors contributing:** all — the phenotype is the whole sensor stack integrated over time.
- **Assumptions for validity:** V3-validated (esp. clinical, on target population); trajectory-based; equitably validated; privacy-preserved; observation-not-diagnosis until cleared.
- **Confidence:** validated wearable biomarkers ★★★★ / phenotyping ★★★ / digital twin ★★. See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Paired chapter this competency: **B13 — Architecture Patterns** (MVVM, Clean/Hexagonal, SOLID, DDD, DI, offline-first) — the code structure the whole engineering track has implicitly followed, made explicit.*
