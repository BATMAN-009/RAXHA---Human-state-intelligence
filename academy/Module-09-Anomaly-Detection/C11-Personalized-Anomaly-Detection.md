# Competency 11 (Science) — Personalized Anomaly Detection

> **Why this is where the philosophy becomes the detector.** Doctrine #16 said "classify changes in people, not people." This competency is the machinery that *does* it. RAXHA cannot enumerate every emergency — falls, cardiac events, seizures, overdoses, assaults all look different, and you will never have labeled training data for most of them. But you *can* learn what is normal *for a specific person* and flag departures from it. That inversion — from "recognize the bad thing" to "notice this isn't this person's normal" — is the only framing that scales to the open-ended set of emergencies RAXHA must catch. This chapter also confronts the hardest honest truth in the whole system: **an anomaly is not an emergency**, and mistaking one for the other is how RAXHA drowns in false alarms.

---

## 1. Definition

**Anomaly detection** is the identification of observations that deviate significantly from an established notion of "normal" — *without* requiring labeled examples of every kind of abnormality. **Personalized** anomaly detection establishes "normal" *per individual* (Decision #16): the baseline is the person, not the population.

The framing shift that makes RAXHA possible:
- **Classification** asks "is this a fall?" — needs labeled falls (rare, diverse, mostly unavailable).
- **Anomaly detection** asks "is this unlike this person's normal?" — needs only *normal* data (abundant: every person generates months of it).

This is **semi-supervised** in the practical sense: you have plentiful "normal" and almost no labeled "abnormal," so you model normal and score deviation. It is the natural statistical frame for a rare-event, open-vocabulary safety problem.

**The load-bearing caveat, stated up front:** *anomaly ≠ emergency.* Most departures from normal are benign — travel, a new gym, a cold, a bad night's sleep, a birthday party. Anomaly detection produces *candidates*; context and corroboration (fusion, C10) and risk scoring (C12) turn a candidate into a decision. An anomaly detector wired straight to an alarm is a false-alarm machine — the base-rate trap (Competency 1) in its final form.

---

## 2. History

Statistical outlier detection is old (Grubbs' test, 1950s; control charts — Shewhart, 1920s, for manufacturing quality). **CUSUM** (Page, 1954) and **EWMA** (Roberts, 1959) brought *change detection* to time series. Machine-learning anomaly detection matured in the 2000s: **One-Class SVM** (Schölkopf, 2001), **Isolation Forest** (Liu, Ting & Zhou, 2008 — isolate anomalies by how easily random splits separate them). Deep anomaly detection (**autoencoders**, **VAEs**, **LSTM autoencoders**, GAN-based) arrived 2015→. In wearables/health specifically, personalized-baseline anomaly detection underlies illness pre-detection (the COVID/flu-from-wearables work, Ch 1.10 §10) and is the frontier for continuous health monitoring.

---

## 3. Scientific Foundation

### 3.1 Modeling "normal" and scoring deviation
Every method is a way to (a) build a model of normal, (b) score how far a new observation is from it. The score is a *distance* or a *reconstruction error* or a *likelihood*, thresholded (with hysteresis and dwell — the recurring lesson) into "anomalous."

### 3.2 The method families (know when to use each)
- **Statistical (interpretable, cheap, TinyML-friendly):**
  - **Z-score / control charts:** flag values beyond N personal standard deviations. Simple, transparent, great MVP.
  - **CUSUM:** cumulative sum of deviations — detects *sustained small shifts* a single-point threshold misses (a slowly rising resting HR over days).
  - **EWMA:** exponentially-weighted moving average — smooths and detects gradual drift; natural for evolving baselines.
- **Classical ML:**
  - **Isolation Forest:** efficient, handles multivariate, no distribution assumption — a strong default for multi-feature anomaly scoring.
  - **One-Class SVM:** learns a boundary around normal; sensitive to parameters.
  - **Gaussian Mixture Models:** model normal as a mixture; score by likelihood.
- **Deep (rich, data-hungry):**
  - **Autoencoder / VAE:** train to reconstruct normal; high reconstruction error = anomaly. The workhorse for high-dimensional/multimodal signals.
  - **LSTM autoencoder:** reconstruct normal *time series*; error flags temporal anomalies (a gait or HR *sequence* that doesn't fit the person's patterns).
- **Change-point detection:** detect *when the distribution shifts* (Bayesian change-point, CUSUM-family) — distinguishing "acute change" (possible event) from "slow drift" (aging, fitness — recalibrate, don't alarm).

### 3.3 The three time-constants (the discipline that prevents false alarms)
A personal baseline lives on three clocks, and confusing them is the field's classic error:
- **Acute (seconds–minutes):** a fall, a cardiac event — sharp deviation → candidate emergency.
- **Sub-acute (hours–days):** illness onset, injury → *observation*/pre-warning, not SOS.
- **Chronic (weeks–months):** aging, fitness change, disease progression, pregnancy → *recalibrate the baseline*, never alarm.
The same numeric deviation means opposite things on different clocks. RAXHA must separate them (change-point + trend modeling) or it will alarm on aging and miss acute events.

### 3.4 Concept drift and online learning
Baselines are non-stationary: they drift with season, fitness, age, life change. A static baseline goes stale (false alarms as the person legitimately changes). **Online/continual learning** updates the baseline — but carefully: adapt too fast and you *normalize a developing pathology* (the baseline chases a slow decline until nothing looks abnormal — a genuine safety failure); adapt too slow and you false-alarm on legitimate change. This adaptation-rate trade-off is a core RAXHA design parameter with a life-critical failure mode on each side.

**The multi-timescale-baseline solution (from the Competency-11 gate, 2026-07-13):** rather than tune a *single* adaptation rate (one dial, bad failure on each end), maintain **several baselines at once** — short-term (days), medium-term (weeks), long-term (months) — and score deviation against *all* of them. A slow pathology (e.g., Parkinson's developing over two years) gets absorbed by the short-term baseline but still reads as anomalous against the long-term one, so the disease can't hide in adaptation; meanwhile genuine healthy change (rehab, fitness) is allowed to become the new normal at the appropriate timescale. This directly realizes the three time-constants (§3.3) as three concurrent models, and it is RAXHA's adopted design for the adaptation-rate problem.

---

## 4–8. Working, Data, Algorithms (RAXHA-specific)

**The RAXHA anomaly pipeline:**
```
fused human-state estimate (C10) + personal baseline (C5/C8)
   → per-signal deviation scores (HR, HRV, gait, activity, mobility, location-routine)
   → multivariate anomaly score (Isolation Forest / autoencoder / statistical ensemble)
   → time-constant separation (acute vs sub-acute vs chronic — change-point)
   → context gating (fusion: is the anomaly explained? travel, exercise, new routine)
   → CANDIDATE (not yet an alert) → Risk Scoring (C12)
```

**What RAXHA models as "normal" per person:** resting/active HR distribution, nightly HRV, gait speed/variability/symmetry, daily activity/mobility patterns, sleep timing, location routine (home/work/known places at expected times). Deviation on any + corroboration across several = a stronger candidate (independent-evidence principle, Competency 1).

**Cold start (Decision #13/#16):** a new user has no baseline → use conservative population priors, wide uncertainty, and *say* "calibrating"; never treat "no baseline yet" as "normal." Baseline confidence grows with tenure — and *that growth is a moat* (the product gets smarter the longer you stay).

**Semi-supervised reality:** model normal (abundant); the rare labeled anomalies you *do* get (confirmed events, user-canceled false alarms from shadow mode — Ch B1) tune thresholds and validate — the fleet's operation is again the label engine.

---

## 9–12. Products, Research, Security, Medical (brief)

**Products:** WHOOP/Oura recovery + "something's off" flags, Apple/Fitbit high/low HR and irregular-rhythm notifications (anomaly detection on a physiological baseline), wearable illness-pre-detection research→products. The pattern: personal-baseline deviation surfaced as *observation*, rarely as *alarm* — because vendors learned anomaly≠emergency the hard way. **Research:** Isolation Forest (Liu 2008), deep anomaly detection surveys, wearable illness-detection (Mishra 2020, Ch 1.10), change-point literature. **Open problems:** distinguishing benign from dangerous anomalies (the whole game), adaptation-rate safety, calibrated anomaly *probabilities* (Decision #18), personalization without centralizing data (federated, Module 13). **Security:** anomaly detection is itself a security tool (detects spoofing/faulty sensors as "anomalous" — ties to fusion, C10), but adversaries can *poison* an online baseline (slowly shift "normal" to hide an attack) → bounded/robust adaptation. **Medical:** personal-baseline deviation is a validated *chronic-risk/illness* signal (★★★), a weaker *acute* one (needs fusion+context); screening-not-diagnosis holds absolutely.

## 13. Engineering for RAXHA

1. **Anomaly detection produces candidates, never alerts** (the §1 caveat as architecture): the detector feeds Risk Scoring (C12), which — with context and policy — decides. Wiring anomaly→alarm is banned (it's the base-rate trap made concrete).
2. **Separate the three time-constants** explicitly (acute→candidate; sub-acute→observation; chronic→recalibrate). One deviation, three meanings.
3. **Bound the adaptation rate** so the baseline can't silently normalize a developing pathology; monitor for it.
4. **Corroborate across signals** (Competency 1's independent-evidence principle): a multivariate anomaly (HR *and* gait *and* activity all off) is far stronger than one signal.
5. **Context-gate with fusion** (C10): explain the anomaly before escalating it (travel, exercise, new routine — the treadmill lesson).
6. **Calibrated anomaly scores** (Decision #18): an anomaly "probability" must mean something to Risk Scoring.
7. **Personal + on-device/federated** (Decision #16, Module 13): the most sensitive baselines (HRV, gait, routine) are biometric — personalize without centralizing.
8. **Cold-start honesty** (Decision #13): calibrating ≠ normal.

## 14. Failure Analysis

| Failure | Mechanism | Mitigation |
|---|---|---|
| Anomaly treated as emergency | Detector wired to alarm | Anomaly = candidate → Risk Scoring decides (§13.1) |
| Alarms on aging/fitness change | Chronic drift read as acute | Time-constant separation; recalibrate, don't alarm |
| Baseline normalizes a decline | Over-fast online adaptation | Bounded adaptation rate; monitor for creeping baseline |
| False alarms on travel/new routine | Context not gated | Fusion context gating; corroborate |
| Cold-start over/under-reaction | New user judged vs population as if personal | Wide priors + "calibrating" state |
| Poisoned baseline | Adversary slowly shifts normal | Robust/bounded adaptation; anomaly on the adaptation itself |
| Uncalibrated anomaly score | Model score ≠ probability | Calibration (Decision #18) before Risk consumes it |
| Misses subtle multivariate event | Single-signal thresholds | Multivariate scoring; cross-signal corroboration |

## 15. RAXHA Application — distilled

- **Use as:** the open-vocabulary detector for the emergencies you can't enumerate or label — "this isn't this person's normal" — feeding candidates to Risk Scoring, and the engine of illness/decline *observation*.
- **Do NOT use as:** an alarm trigger by itself (anomaly≠emergency); a static model (drift); an over-adaptive model (normalizes pathology); a population-baseline judge of an individual.
- **One-liner:** *anomaly detection is how RAXHA catches the emergencies nobody trained it for — by knowing you well enough to notice when you're not yourself, then asking context whether that matters.*

## 16. Future

Calibrated, personalized, federated anomaly detection; foundation-model baselines (pretrain population, personalize per user); the convergence of fusion + baselines + anomaly into a continuous personalized *human-state model* (the "digital twin," Module 10); causal anomaly detection (why is this abnormal, not just that it is) for explainable alerts.

## 17. Mastery Test — Competency 11

1. Why is anomaly detection (not classification) the natural frame for RAXHA's emergencies? What data does each need, and why does that decide it?
2. State and defend the caveat "anomaly ≠ emergency." What turns an anomaly into a decision, and what happens if you skip that?
3. Explain the three time-constants (acute/sub-acute/chronic). Why does the *same* deviation mean opposite things on each, and what must RAXHA do differently for each?
4. Explain the adaptation-rate trade-off and its life-critical failure mode on *both* ends (too fast and too slow).
5. Why must anomaly scores be *calibrated* (Decision #18) before Risk Scoring consumes them?
6. How does personalized anomaly detection operationalize Decision #16, and why is it also privacy-protective?
7. **[Standing gate question]** If RAXHA shipped personalized anomaly detection tomorrow, what's the single most likely field failure — scientific, platform, or product?

## 18. Founder Intelligence

**Why hasn't this been "solved"?** Distinguishing *dangerous* anomalies from *benign* ones is genuinely open — most deviations are harmless, and the labels to learn the difference (real emergencies) are scarce. Vendors ship anomaly detection as *observation* (WHOOP "something's off," Apple irregular-rhythm) precisely because they can't reliably call emergencies from anomalies alone. **The moat:** personalized baselines *compound with tenure and scale* — the longer a user stays and the more users you have, the better your normal-model and your (shadow-mode) sense of which anomalies matter. This is the data flywheel (C9) applied to baselines — copyable algorithm, uncopyable personalized-baseline-plus-outcome dataset. **WHOOP/Oura** are anomaly-on-personal-baseline businesses; RAXHA extends the frame to *safety* (with the fusion/context/risk stack they lack). **Why doesn't everyone build safety anomaly detection?** anomaly≠emergency is a false-alarm minefield; the base-rate trap punishes naïveté; and it needs the whole stack beneath it. **Startup opportunities:** personalized health-anomaly infrastructure, illness pre-detection, elder-decline monitoring, calibrated-anomaly-as-a-service. **RAXHA strategy:** anomaly detection is what lets RAXHA catch the *long tail* of emergencies (not just falls/crashes) — the expansion from "fall detector" to "human-state safety system" — but always as candidates into Risk Scoring, never as direct alarms. **PhD gaps:** benign-vs-dangerous anomaly discrimination, adaptation-rate safety, calibrated personalized anomaly probability, federated baseline learning. **Patents:** health-anomaly/baseline families (WHOOP/Apple/Fitbit — query `personalized baseline anomaly detection wearable assignee:X`). **Ledger:** ✅ methods (public), consumer anomaly features; 🟡 vendor baseline/threshold algorithms; 🔴 outcome-labeled datasets (the scarce asset).

## 19. Design Review (highlights)

- **Chief Scientist:** "Show me anomaly *probabilities* are calibrated and that you separated the three time-constants. An uncalibrated anomaly score into Risk Scoring is Decision #18 violated."
- **Physician:** "Most anomalies are nothing. Prove your baseline can't slowly normalize a real decline, and that you don't alarm my patients for aging."
- **Investor:** "Anomaly-on-personal-baseline is the WHOOP business — and your safety framing extends it. The baseline flywheel is the moat. How fast does it compound?"
- **Privacy advocate:** "Personal baselines (HRV, gait, routine) are the most intimate data you hold. On-device/federated, no central baseline DB."
- **ML reviewer:** "Report anomaly-detector performance as precision/recall on *confirmed* events with FA/person-week, never 'accuracy.' And show the benign-anomaly rate."

## 20. Constraint Exercise

Design RAXHA's personalized anomaly detector for physiological + mobility decline. Constraints: model normal per-user with no labeled emergencies, separate the three time-constants, bound adaptation so it can't normalize a decline, output *calibrated* candidate scores (not alarms) to Risk Scoring, keep baselines on-device/federated, and handle cold-start honestly. Specify: the per-signal models, the multivariate scoring, the time-constant separation, the adaptation-rate policy + its safety monitor, the calibration method, and the exact candidate handed to C12. One-page memo.

## 21. Chief Scientist's Verdict

**Confidence Ledger:** Personal-baseline anomaly detection as the right frame for rare/open-vocabulary events — ★★★★★ (methodologically sound). Statistical/IsolationForest/autoencoder methods — ★★★★★ (mature). "Anomaly ≠ emergency; needs context/risk" — ★★★★★ (the core discipline). Distinguishing dangerous from benign anomalies reliably — ★★★☆☆ (**the open, differentiated problem**). Calibrated personalized anomaly probability — ★★★☆☆. Safe adaptation rate — ★★★☆☆ (real failure modes both ends).
**TRL:** Statistical/classical anomaly detection — 9. Deep/personalized anomaly — 6–7. Calibrated safety-grade anomaly candidates — 4–5 (RAXHA's build). Federated personal baselines — 5–6.
**Roadmap:** *MVP:* statistical personal-baseline deviation (z/CUSUM/EWMA) → candidates → Risk Scoring; observation-only illness/decline flags. *V2:* multivariate (Isolation Forest/autoencoder), calibrated scores, time-constant separation, federated baselines. *Research:* benign-vs-dangerous discrimination, causal/explainable anomalies. *Never Build:* anomaly→alarm direct wiring; static baselines; over-adaptive baselines; population-judges-individual; uncalibrated scores into Risk.
**Competitor failures (sourced):** consumer "something's off"/recovery scores criticized for noise and benign-anomaly false flags (documented reviewer skepticism) — the anomaly≠emergency lesson, learned publicly. Health apps that implied emergency/diagnostic conclusions from anomalies drawing regulatory attention (the ★★-claim/★★★★★-marketing pattern). The base-rate trap's body count across alerting systems (alarm fatigue in clinical monitoring — well-documented) — too many anomaly alarms and everyone stops listening.
**Kill Criteria:** if the detector can't keep benign-anomaly candidate rate low enough that Risk Scoring + context yields acceptable FA/person-week, tighten to fewer, higher-confidence signals. If adaptation can't be bounded safely (no baseline-normalizes-pathology in testing), slow or freeze adaptation and recalibrate deliberately. If anomaly scores can't be calibrated, feed Risk conservative rules, not false-confident probabilities.
**Historical Failures (Historian):** clinical alarm fatigue (extensively documented — nurses desensitized by too many monitor alarms, real events missed) — the definitive cautionary tale for anomaly→alarm systems; RAXHA's candidate→risk→context discipline is the structural defense. Consumer health-anomaly overclaims (illness/condition inferences ahead of validation) — the recurring evidence-vs-marketing failure the Confidence Ledger exists to stop.

## 22. Knowledge Graph Connections

- **Depends on (prior):** C5 HR/HRV baseline (the founding personal-baseline), C8 gait baseline, C9 HAR (activity context), C10 fusion (fused state + calibrated confidence is the input), Decisions #13/#16/#18.
- **Depended on by (future):** C12 Risk Scoring (consumes anomaly candidates), Context Engine, Emergency Decision; Module 10 digital biomarkers (anomaly on biomarkers); Module 13 (federated baselines).
- **RAXHA subsystem:** the detector feeding Risk Scoring; the illness/decline observation engine.
- **AI models:** statistical (z/CUSUM/EWMA), Isolation Forest, One-Class SVM, GMM, autoencoder/VAE/LSTM-AE, change-point.
- **Sensors contributing:** all — via the fused state and per-signal baselines (HR, HRV, gait, activity, mobility, location-routine).
- **Assumptions for validity:** enough normal data (cold-start=wide priors); calibrated scores; time-constants separated; bounded adaptation; anomaly=candidate not alarm; on-device/federated baselines.
- **Confidence:** frame ★★★★★ / dangerous-vs-benign discrimination ★★★ / calibrated safety candidates ★★★. See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Paired chapter this competency: **B10 — Backend: Alert Delivery, Push, Telephony & Live Location** — where a decision finally becomes a delivered alert.*
