# Competency 8 — Human Gait Intelligence

> **Why this is a standalone competency, not a sensor chapter.** Gait is not an activity RAXHA classifies; it is an *intelligence layer* RAXHA reasons with. Your walk is simultaneously a **clinical vital sign** (gait speed is "the sixth vital sign"), a **behavioral biomarker** (deterioration predicts falls, illness, decline — often before the person notices), and a **biometric identity** (you can be recognized, and tracked, by how you move). This competency is the bridge from *physiology* (what the body is doing internally) to *HAR* (what the person is doing behaviorally) — and it integrates every sensor learned so far: accelerometer, gyroscope, magnetometer, IMU, PPG, HR/HRV, barometer, and GPS. It follows the full §1–22 template and is taught in the three domains you specified, each ending in RAXHA application.

---

## 1. Definition

**Gait** is the pattern of locomotion — the coordinated cycle of limb and trunk movement that carries a body through space. **Gait analysis** quantifies it; **gait recognition** identifies a person by it; **behavioral gait intelligence** tracks how it changes over time to infer health and state.

The **gait cycle** is the atomic unit: one full stride from heel-strike of one foot to the next heel-strike of the *same* foot, divided into **stance phase** (~60%, foot on ground) and **swing phase** (~40%, foot in air), with two brief **double-support** periods (both feet down) that vanish in running and lengthen in the frail and cautious. Every metric in this competency is defined on this cycle.

Three framings, one signal:
- **Clinical:** *how well* does this person walk? (speed, symmetry, variability → frailty, disease, fall risk)
- **Behavioral:** *how is this person's walking changing?* (longitudinal baseline → decline, illness, fatigue, recovery, wandering)
- **Identity:** *who is this person, from their walk?* (biometric recognition, wearer verification — and the privacy threat that comes with it)

---

## 2. History

Gait study is ancient (Aristotle, *De Motu Animalium*) but quantitative gait analysis begins with **Étienne-Jules Marey** and **Eadweard Muybridge** (1870s–80s) — chronophotography freezing the walk cycle frame by frame. Clinical gait labs with force plates and optical motion capture matured mid-20th century (Vicon-style systems remain the gold standard). **Gait speed as a mortality/frailty predictor** was established in large geriatric cohorts (Studenski et al., *JAMA* 2011 — pooled analysis linking gait speed to survival in older adults; the citation behind "sixth vital sign"). **Wearable gait analysis** (accelerometer-derived) exploded in the 2000s–2010s as MEMS IMUs became ubiquitous, moving gait out of the lab and onto the wrist/waist/shoe. **Gait recognition** as a biometric emerged in computer vision (1990s–2000s, silhouette-based) and in wearables/RF sensing more recently — including the device-free Wi-Fi identification you just read about (KIT BFId, CCS 2025 — [[RF-WiFi-sensing-BFId-KIT-2025]]).

---

## 3. Scientific Foundation — the gait cycle and its measurable parameters

**Spatiotemporal parameters** (the clinically and behaviorally load-bearing ones):
- **Cadence** — steps per minute.
- **Stride/step length** — distance per cycle/step (stride = two steps).
- **Gait speed** — distance/time; the master metric ("sixth vital sign"). ~1.2–1.4 m/s is typical healthy adult; <1.0 m/s flags increased frailty/fall risk; <0.6 m/s is strongly associated with adverse outcomes.
- **Step width** — lateral base of support; *wider* signals balance compensation.
- **Double-support time** — *longer* signals caution/instability (the body minimizing single-leg time).
- **Symmetry** — left-vs-right similarity; asymmetry flags injury, stroke, unilateral pathology.
- **Gait variability** — stride-to-stride fluctuation (in time or length). **This is the crown jewel: increased variability is one of the strongest predictors of future falls,** independent of speed, and it's exactly the kind of subtle personal-baseline deviation RAXHA is built to detect (Competency 5's thesis, now applied to movement).

**Where it comes from on a wrist (the honest caveat):** clinical gait is measured at the *pelvis/trunk/feet*; RAXHA reads the *wrist*, which swings semi-independently of the body (Competency 2's "the wrist lies about the body"). Wrist gait analysis is therefore *approximate* — cadence and gross speed are recoverable, fine symmetry and true stride length are harder — and this limitation shapes every RAXHA claim below. Waist/pocket phone placement and future foot sensors give richer gait; the wrist gives a robust-but-coarse view.

**The physics of extraction:** walking produces a quasi-periodic acceleration signature (the step "bounce" and arm swing); step detection = peak detection / autocorrelation / spectral dominant-frequency on the accel signal (the same machinery as PPG cadence artifact — Chapter 1.8 — which is why gait and heart rate are entangled at the wrist). Stride length is *estimated* (from step frequency + height models, or double-integrated acceleration with heavy drift correction — the PDR problem of Chapter 1.7). Heading (gyro+mag) turns steps into a path.

---

## DOMAIN 1 — Clinical Gait Analysis

**What it is:** using gait parameters as clinical indicators of health, disease, and risk.

**Disease signatures (each a recognizable gait pattern):**
- **Parkinson's:** shuffling, reduced arm swing, festination (involuntary acceleration), freezing of gait, increased variability. Wearable gait is a validated PD monitoring tool (★★★★).
- **Stroke/hemiparesis:** asymmetric gait, circumduction, foot drop.
- **Dementia:** slowing and increased variability often *precede* cognitive diagnosis (gait as an early marker); plus wandering behavior (Domain 2).
- **Musculoskeletal (arthritis, post-injury):** antalgic (pain-avoiding) gait, asymmetry, reduced speed.
- **Frailty / sarcopenia:** slow speed, short strides, wide base, long double-support.

**Fall-risk prediction (the RAXHA-critical distinction):** this is *predicting a future fall* from deteriorating gait — a fundamentally different and richer problem than *detecting a fall in progress* (Competencies 1–2). Increased gait variability, slowed speed, and reduced symmetry are established fall-risk markers. Prediction enables *prevention* (alert caregivers to rising risk before the fall), which is a categorically higher-value proposition than fast response after the fact.

**Clinical context:** gait speed predicts survival, hospitalization, and cognitive decline in older adults (Studenski 2011 lineage); Timed-Up-and-Go and gait-speed tests are standard geriatric assessments. RAXHA can *continuously and passively* estimate what a clinic measures once a year — the wearable's structural advantage.

**RAXHA application (Domain 1):** continuous passive gait-speed and variability estimation → a **fall-risk score** that rises before a fall, enabling caregiver pre-warning (V2/V3 roadmap, framed as *risk observation* not diagnosis — the screening/diagnosis line from Chapter 1.8/1.10 holds absolutely). Wrist-limitation honesty: report trends and relative change, not clinical-grade absolute gait speed, unless validated.

---

## DOMAIN 2 — Behavioral Gait Intelligence

**What it is:** gait as a **longitudinal digital biomarker** — not a single measurement, but a *personal baseline* tracked over time, where *deviation* carries meaning (Competency 5's entire philosophy, now applied to movement).

**What the baseline reveals:**
- **Mobility decline:** slow drift toward shorter, slower, more variable gait → aging, disease progression, deconditioning.
- **Acute change:** a sudden gait shift → acute illness, injury, intoxication, medication effect, stroke onset.
- **Fatigue:** within-day gait degradation → tiredness, overexertion (athletic or occupational — lone-worker safety).
- **Stress effects:** psychological state subtly alters gait (pace, agitation) — a ★★ inferential signal, handle with care.
- **Recovery tracking:** gait improving post-injury/surgery → rehabilitation progress (a positive, motivating use case).
- **Wandering detection (dementia elopement):** gait + location + time-of-day patterns identify a person leaving a safe zone in a manner inconsistent with their routine — the behavioral-anomaly use case that fuses gait (Domain) + geofencing (Chapter 1.6/1.7) + baseline.
- **Child behavior / senior monitoring:** age-appropriate movement baselines; deviations flag distress or wandering.

**The method (the connective tissue of the whole curriculum):** build a **personal gait baseline** (distribution of speed, cadence, variability, symmetry under matched conditions), score deviation in personal standard deviations (not population absolutes), separate slow *trend* from acute *change* (different time constants), and gate on context (don't compare running gait to strolling gait). This *is* anomaly detection (Module 9), previewed with gait as the signal.

**RAXHA application (Domain 2):** gait becomes a continuous **state-and-decline sensor** feeding the personal baseline that makes every other detector smarter — and a standalone slow-warning channel (rising fall-risk, mobility decline, possible acute change → *observation* alerts, never diagnosis). Wandering detection is a concrete, high-value, shippable feature fusing gait + geofence + routine.

---

## DOMAIN 3 — Gait Recognition & Privacy

**What it is:** gait as a **behavioral biometric** — identifying or verifying *who* someone is by how they move.

**Two faces, opposite signs:**
- **Feature (for RAXHA):** **wearer verification / continuous authentication.** "Is the registered user the one wearing this watch right now?" Gait-based wearer confidence directly serves Decision #14 (non-wear / wrong-wearer): if the gait signature doesn't match the enrolled user, RAXHA's confidence that it's protecting the *right person* drops. Continuous, passive, frictionless authentication — no PIN, no biometric prompt.
- **Threat (against everyone):** **surveillance and tracking.** Gait identifies people at a distance, through cameras, and — per the KIT BFId result ([[RF-WiFi-sensing-BFId-KIT-2025]]) — even device-free through Wi-Fi body reflections, with no consent and no wearable. Your walk is a fingerprint you can't easily change.

**Techniques:** vision-based (silhouette/skeleton gait recognition), wearable-IMU gait signatures (accelerometer gait templates — the AccelPrint lineage of Chapter 1.1 §11 applied to identity), and RF/Wi-Fi sensing (CSI/BFI). Accuracy in controlled studies is high (the KIT "near 100% on 197" is ✅ peer-reviewed but ★★★ for real-world generalization — lab≠field, the recurring honesty check).

**Adversarial & spoofing:** gait can be *mimicked* (an impostor copying a walk) or *obscured* (deliberately altering gait); adversarial perturbations can fool gait classifiers. For RAXHA's wearer-verification use, this means gait auth is a *confidence contributor*, never a hard gate — consistent with the whole architecture (no single signal is sole authority, Decision #11).

**Ethics & defense:** gait data is identifying → strict privacy tier; on-device gait templates, never a centralized gait database (the movement-fingerprint version of the location-broker lesson); users must consent to gait-based features; and RAXHA should *educate* that motion data is biometric. The KIT result is a reminder that RAXHA's own accelerometer streams are identity-bearing and must be protected accordingly.

**RAXHA application (Domain 3):** gait-based **wearer-identity confidence** as an input to the "is the right person protected?" question (Decision #14), on-device only, as a soft confidence signal — plus a threat-model entry: RAXHA's motion data is a biometric to be defended, and RAXHA must never build the surveillance capability its own sensors could enable.

---

## 4–8. Internal Working, Hardware, Software, Data, Algorithms (integrated)

**Signal path:** IMU (accel+gyro, calibrated per Ch 1.3/1.4) → step detection & segmentation into gait cycles → per-cycle spatiotemporal parameters → windowed features (mean, variability, symmetry, spectral) → {clinical scoring | baseline deviation | identity template}. Barometer adds stair/incline context; GPS adds outdoor speed ground-truth (calibrating stride models); PPG/HR adds exertion context (is slow gait fatigue or caution?).

**Software:** `CMPedometer` (iOS) and `StepCounter`/Health Services (Android/Wear) give steps/distance/cadence as platform primitives; richer gait parameters are computed from raw IMU (the B5 acquisition layer) or consumed from platform "walking steadiness"-type metrics (Apple's **Walking Steadiness**, ✅, is a shipped wrist/phone gait-quality/fall-risk feature — a direct precedent).

**Algorithms:** step detection (peak/autocorrelation/spectral); stride-length estimation (frequency+height models, or drift-corrected double integration — PDR overlap); variability/symmetry statistics; **HAR/deep models** for gait classification and abnormality detection (CNN/LSTM/Transformer on gait windows — the same lineage as Ch 1.1 §8, and the doorway to Competency 9); **gait-recognition models** (template matching, metric learning, deep embeddings) for identity; **personal-baseline anomaly models** (Module 9) for behavioral decline.

---

## 9–12. Real Products, Research, Security, Medical (integrated)

**Products:** Apple **Walking Steadiness** + gait metrics (walking speed, step length, double-support %, asymmetry) in Health — the clearest shipped precedent for wrist/phone clinical-gait-as-fall-risk (✅). Google/Fitbit cadence/pace. Clinical gait labs (Vicon, force plates) = gold standard. PD-monitoring wearables (research + some cleared products). Vision gait-recognition in surveillance (deployed, controversial). **Research:** Marey/Muybridge (origins); Studenski 2011 (gait speed & survival); Hausdorff (gait variability & fall risk — foundational); wearable-gait and gait-recognition literature; KIT BFId 2025 (device-free RF ID). **Security/privacy:** gait is a biometric (AccelPrint lineage; KIT RF sensing) → identifying data, strict handling, no central gait DB, on-device templates. **Medical:** gait speed = validated vital-sign-grade marker (★★★★); PD/stroke/frailty gait signatures validated (★★★★); wrist-derived clinical-grade absolute gait = harder (★★★); fall-*risk* prediction from gait = ★★★–★★★★ (strong markers, prediction is probabilistic); screening not diagnosis, always.

---

## 13. Engineering for RAXHA (synthesis)

1. **Gait is a core intelligence layer, computed continuously and cheaply** from the always-on IMU — it feeds fall-risk (Domain 1), the personal baseline & wandering (Domain 2), and wearer verification (Domain 3) simultaneously.
2. **Wrist-honesty:** report gait *trends and relative change* confidently; treat absolute clinical gait speed as approximate unless validated against a richer placement.
3. **Fall-*risk* is a distinct, higher-value product than fall-*detection*:** prevention > response. Ship it as risk *observation* (caregiver pre-warning), never diagnosis.
4. **Wandering detection** = gait + geofence + routine baseline — concrete, shippable, high-value for dementia care.
5. **Wearer verification** = gait-identity as a *soft* confidence input to "right person protected?" (Decision #14), on-device only.
6. **Privacy is load-bearing:** gait templates on-device, no central gait database, explicit consent, and a threat-model entry acknowledging RAXHA's motion data is biometric (KIT lesson).

---

## 14. Failure Analysis

| Failure | Mechanism | Mitigation |
|---|---|---|
| Wrist gait ≠ body gait | Arm swings independently | Report trends/relative; don't claim clinical absolute speed |
| Compares running to strolling | No context gating | Match conditions before baseline comparison |
| False "decline" alarm | Baseline drift (travel, terrain, footwear) | Multi-day trends, wide priors, observation-not-diagnosis framing |
| Wearer-auth false reject | Gait varies (injury, load, fatigue) | Soft confidence input, never a hard gate |
| Privacy leak | Gait templates centralized / motion data unprotected | On-device templates; strict tier; no gait DB; consent |
| Over-claims fall prediction | ★★★ prediction sold as certainty | Probabilistic risk framing; kill criteria on false-alarm/anxiety |
| Missed decline | Too-coarse wrist signal | Fuse with HR/HRV, activity, optional richer placement |

---

## 15. RAXHA Application — distilled

- **Use as:** (Domain 1) continuous fall-*risk* estimation for prevention; (Domain 2) the personal mobility baseline + wandering detection + decline warning; (Domain 3) on-device wearer-identity confidence for "right person protected."
- **Do NOT use as:** a clinical diagnostic; a hard authentication gate; a centralized surveillance/identity capability; a source of confident absolute clinical gait speed from the wrist alone.
- **One-liner:** *gait is where RAXHA stops asking "did something just happen?" and starts asking "is this person's trajectory of health and safety changing?" — the shift from response to foresight.*

---

## 16. Future

Passive continuous clinical-grade gait from consumer wearables; validated fall-*prediction* (prevention products); multimodal gait+physiology "digital twin" of mobility (Module 10); federated gait-baseline learning (personalize without centralizing biometrics — Module 13); the double-edged rise of device-free RF gait sensing (KIT-style) as both capability and threat.

---

## 17. Mastery Test — Competency 8

1. Define the gait cycle and explain why increased gait *variability* is a more powerful fall-risk signal than gait speed alone.
2. Distinguish fall-*detection* from fall-*prediction*. Why is prediction categorically higher-value, and why is it also harder to claim responsibly?
3. Why is wrist-derived gait "approximate," and what does that force RAXHA to claim vs. refuse to claim (tie to the Competency-2 "wrist lies about the body" lesson)?
4. Explain gait as *both* a RAXHA feature (wearer verification) and a societal threat (device-free RF identification, KIT BFId). How should RAXHA hold both truths?
5. Design the wandering-detection feature: which signals fuse (name them across competencies), what the baseline is, and how you avoid false alarms.
6. Why does gait belong *between* physiology and HAR in the curriculum — what does it take from Competencies 1–7 and give to Competency 9?
7. **[Standing gate question]** If RAXHA shipped gait-based fall-risk prediction tomorrow, what's the single most likely field failure — scientific, platform, or product?

---

## 18. Founder Intelligence

**Why hasn't Apple "solved" gait?** It's partway — **Walking Steadiness** (✅) is shipped fall-risk-from-gait, proof the category is real and Apple is in it. But wrist-limitation, the prediction-vs-detection gap, and the clinical-validation burden keep it conservative (observation, not diagnosis). **WHOOP/Oura:** body-state focus; gait is peripheral to recovery/sleep models. **Garmin:** running dynamics (cadence, ground-contact, vertical oscillation) — gait-as-athletic-performance, a whole paid feature set; proof gait analysis monetizes. **Google/Fitbit:** cadence, mobility metrics. **Clinical/PD-monitoring startups:** gait as disease biomarker (a real vertical). **Vision/RF surveillance vendors:** gait recognition as identity (the controversial edge). **Why doesn't everyone build gait fall-*prediction*?** Prediction is probabilistic (hard to market honestly), clinical validation is slow, wrist signal is coarse, and false "you're declining" alarms cause anxiety. **Startup opportunities:** passive fall-*risk* for elder care (prevention sold to families/insurers/facilities — higher value than detection), PD/neuro monitoring, rehab-progress tracking, wandering-detection for dementia care, athletic gait coaching, gait-based frictionless auth. **RAXHA strategy:** gait is the layer that elevates RAXHA from *reactive* (fall happened) to *predictive* (fall risk rising) — the single biggest expansion of the value proposition in the whole curriculum, and a compounding, personalized moat. But claim probabilistically, validate before medical claims, and treat gait as biometric. **PhD gaps:** validated wrist fall-prediction; clinical-grade wrist gait; label-free gait-baseline personalization; privacy-preserving gait auth; defending against device-free gait surveillance. **Patents:** Apple Walking Steadiness / gait-metric families (query `assignee:"Apple Inc." walking steadiness gait`); gait-recognition families (vision + wearable); PD-gait monitoring. **Ledger:** ✅ Walking Steadiness, gait-speed clinical evidence, KIT BFId; 🟡 vendor gait algorithms; 🔴 training data, exact fall-prediction models.

## 19. Design Review (highlights)

- **Emergency physician:** "Fall *prediction* is the holy grail — prevent, don't just respond. But wrist gait is coarse and prediction is probabilistic. Give caregivers a *risk trend*, never a false 'they will fall,' and validate on my population before any clinical claim."
- **Privacy advocate:** "Gait is a biometric — the KIT result proves people are identifiable by movement with no device. On-device templates, no gait database, explicit consent, and be honest that your accelerometer stream is identifying data."
- **Chief Scientist:** "Show me you separated slow decline from acute change with proper time constants, and that you gate context (running vs strolling) before any baseline deviation. Otherwise your 'decline' alarms are footwear and terrain."
- **Investor:** "Prediction/prevention is a bigger, stickier market than detection — elder-care and insurers pay for risk reduction. This is the value-prop expansion. What's the validation timeline?"
- **FDA reviewer:** "Fall-risk 'observation' is fine; 'this patient will fall' or disease diagnosis crosses into device territory. Version your claims."

## 20. Constraint Exercise

Design RAXHA's gait-based **fall-risk-prevention** feature for an elder-care deployment. Constraints: wrist-only signal (coarse), ★★★ prediction evidence, a false-"declining" rate that must not cause anxiety or alarm fatigue, cold-start users with no baseline, on-device gait templates (privacy), and a hard no-diagnosis rule. Specify: the gait parameters used, the personal-baseline model + time constants, the risk-trend output (and its exact caregiver-facing language), the context gating, the privacy/consent design, and what you refuse to claim. One-page memo.

## 21. Chief Scientist's Verdict

**Confidence Ledger:** Gait speed as clinical/mortality marker — ★★★★★ (clinical, ECG-of-gait). Gait variability as fall-risk predictor — ★★★★☆ (strong literature; wrist-derived weaker). PD/stroke/frailty gait signatures — ★★★★☆. Wrist-derived *absolute* clinical gait speed — ★★★☆☆ (approximate). Fall-*prediction* from wrist gait (actionable) — ★★★☆☆ (**promising, the key ambition-vs-evidence gap**). Gait recognition / wearer verification — ★★★☆☆ (high in lab, field-variable). Device-free RF gait ID (KIT) — ★★★☆☆ (✅ peer-reviewed, one study, real-world generalization unproven). Gait-based stress inference — ★★☆☆☆.
**TRL:** Wearable gait metrics (cadence/speed/steadiness) — 8–9 (shipped, Apple). Clinical-grade wrist gait — 5–6. Fall-*prediction* products — 5–6. Gait recognition (vision) — 7–8; (wearable/RF) — 4–6. Wandering detection (gait+geo+routine) — 6–7.
**Roadmap:** *MVP:* passive cadence/speed/steadiness trends + personal mobility baseline. *V2:* fall-*risk* observation (caregiver pre-warning), wandering detection, on-device wearer verification. *Research:* validated fall-prediction, clinical-grade wrist gait, privacy-preserving gait auth. *Never Build:* gait *diagnosis*; centralized gait/identity database; device-free surveillance capability; hard gait auth gate.
**Competitor failures (sourced):** consumer "walking analysis" features criticized for wrist-inaccuracy vs lab; gait-recognition surveillance deployments drawing documented civil-liberties backlash — a warning that the *identity* face of gait is a reputational minefield; PD-monitoring startups that over-claimed diagnostic capability ahead of validation (the ★★ claim / ★★★★★ marketing pattern).
**Kill Criteria:** if wrist fall-prediction can't beat a false-"declining"/anxiety threshold in shadow mode, ship gait as passive trend-visualization + fall-*detection* only. If gait-wearer-verification false-reject rate harms usability, keep it a soft confidence signal, never a gate. If any gait feature requires centralizing biometric templates to work, redesign for on-device/federated before launch.
**Historical Failures (Historian):** the broader "we can predict falls" wearable wave — several products implied prediction they hadn't validated; credibility damage. Gait-recognition surveillance controversies (deployments halted over privacy/bias) — the identity face of gait is where a safety brand can become a surveillance villain; RAXHA's on-device/consent/no-database posture is the structural defense. Vision gait-recognition bias findings (accuracy varying across demographics) — the equity lesson from PPG (Ch 1.8) recurs: a biometric that works unevenly across groups is inequitable, not just inaccurate.

## 22. Knowledge Graph Connections

- **Depends on (prior):** C1 accel (step detection), C2 gyro (rotation/heading), C3–4 IMU+calibration (clean gait features), C5 HR/HRV (exertion context; the personal-baseline *method* reused here), C6/C7 GPS/PDR (stride ground-truth, path, wandering location), C1.16 barometer (stairs/floor). Integrates nearly the entire sensor stack — hence a standalone competency.
- **Depended on by (future):** C9 HAR (gait is the base locomotion primitive HAR builds on); C10 fusion (gait+location+physiology); Module 9 anomaly detection (gait baseline = a prime anomaly signal); Module 10 digital biomarkers (gait is a flagship biomarker); Context Engine, Risk Scoring, Decision #14 (wearer verification).
- **RAXHA subsystem:** Personal Baseline Engine (Domain 2), Fall-Risk/Prevention scoring (Domain 1), Wearer-Identity confidence (Domain 3), Context Engine, Wandering detection.
- **AI models consuming it:** step/gait extractors; deep gait classifiers (CNN/LSTM/Transformer); personal-baseline anomaly models; gait-recognition embeddings.
- **Sensors contributing:** accel, gyro, mag, barometer, GPS, PPG/HR (context).
- **Assumptions for validity:** wrist gait is approximate (trends not clinical absolutes); context-matched baseline comparison; enough history (cold-start = wide priors); gait templates stay on-device.
- **Confidence:** gait-speed marker ★★★★★ / wrist absolute ★★★ / fall-prediction ★★★ / recognition ★★★. See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Paired next competency: **Competency 9 — Human Activity Recognition (HAR)** (Module 7) + **B8 — TinyML Deployment**. Gait is the locomotion primitive; HAR is the full behavioral vocabulary built on top of it.*
