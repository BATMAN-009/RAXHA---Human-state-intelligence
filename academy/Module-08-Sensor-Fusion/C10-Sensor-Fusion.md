# Competency 10 (Science) — Sensor Fusion

> **Why this is the culmination.** Nine competencies produced nine imperfect witnesses, each with a signature lie: the accelerometer can't separate gravity from motion, the gyro drifts, the magnetometer lies indoors, PPG fails under motion, GPS is confidently wrong in cities, HAR mislabels, gait is coarse at the wrist. Sensor fusion is the layer that makes these *collectively* trustworthy — not by trusting any one, but by combining each estimate *weighted by its uncertainty* into a single state that is more accurate and more robust than any input. This is where your own Competency-6 principle becomes mathematics: *every sensor produces an estimate, not a fact; the job is to quantify uncertainty, combine independent evidence, and produce the safest estimate given what's knowable.* Fusion is that sentence, formalized.

---

## 1. Definition

**Sensor fusion** is the combination of data from multiple sensors (or multiple sources) to produce a state estimate that is more accurate, more complete, or more reliable than any single source — *and*, critically, that carries a principled measure of its own uncertainty. The output of fusion is not just "the answer"; it is "the answer, and how sure we are."

Three levels (your seed's taxonomy, now precise):
- **Early / data-level:** combine raw signals before feature extraction (e.g., PPG + accelerometer at the signal layer for motion-robust HR — Ch 1.8). Highest information, highest coupling.
- **Feature-level:** concatenate per-sensor features, then classify (e.g., accel+gyro features into the HAR/fall confirmer — Ch 1.1/C9).
- **Late / decision-level:** each sensor/model produces a decision or estimate, then combine (e.g., fuse fall-cascade output + location context + HR context into a risk score). Most modular, most robust to a single bad source.

RAXHA uses **all three**: signal-level (PPG+accel), feature-level (IMU→HAR), and decision-level (state+context→risk). The whole architecture is a fusion hierarchy.

---

## 2. History

- **1960 — Rudolf Kálmán**, "A New Approach to Linear Filtering and Prediction Problems" (*J. Basic Eng.*). The Kalman filter — recursive optimal estimation for linear-Gaussian systems. **Apollo's guidance computer used it to fuse IMU + star-tracker data to navigate to the Moon** — the same math, 60 years before your watch.
- **1960s–70s:** Extended Kalman Filter (EKF) for nonlinear systems (aerospace, missiles); the strapdown-inertial-navigation canon (Titterton & Weston).
- **1979 — Dempster–Shafer** evidence theory (an alternative to Bayesian fusion for reasoning under ignorance).
- **1990s–2000s:** Unscented Kalman Filter (Julier & Uhlmann — better nonlinear handling); Particle Filters (Gordon et al. 1993 — Monte-Carlo estimation for non-Gaussian, multimodal problems); multi-target tracking (Bar-Shalom).
- **2010–11 — Madgwick** and **Mahony** filters: efficient open-source orientation fusion (IMU/MARG) that made good attitude estimation cheap enough for any wearable — the algorithms behind your watch's orientation.
- **2015→ (deep era):** learned fusion — RNNs/Transformers ingesting multi-sensor time series; deep Kalman filters; differentiable filtering. The frontier blends principled filtering with learned models.

---

## 3. Scientific Foundation

### 3.1 Fusion is Bayesian belief updating
The unifying idea: maintain a **belief** about the state (a probability distribution), and update it as evidence arrives:
$$p(\text{state} \mid \text{measurements}) \propto p(\text{measurement} \mid \text{state}) \cdot p(\text{state})$$
Posterior ∝ likelihood × prior. Every fusion algorithm is a way of doing this recursively and efficiently. The **prior** is your prediction (where you expected the state to be); the **likelihood** is what the sensor says; the **posterior** is the fused estimate — and it is always *more certain* than either input when they agree, and *appropriately uncertain* when they conflict.

### 3.2 The Kalman filter — predict/update, weighted by uncertainty
For linear-Gaussian systems, the Kalman filter is the *optimal* estimator. Two steps, forever repeating:
- **Predict:** propagate the state forward using a motion model; uncertainty (covariance) *grows* (you're less sure the longer you coast — this is exactly gyro drift and GPS-outage dead-reckoning).
- **Update:** a measurement arrives; blend prediction and measurement, each weighted by its inverse uncertainty. The **Kalman gain** is literally "how much do I trust this measurement vs my prediction" — high-accuracy measurement → gain toward the measurement; noisy measurement → gain toward the prediction.

This *is* the "accuracy is a field, propagate it" rule (Ch 1.6) and the gated-absolute-reference pattern (Ch 1.3/1.4), formalized: the filter automatically down-weights a noisy GPS fix or a drifting gyro *in proportion to its stated uncertainty*. **The complementary filter** (Ch 1.3/1.4 §8) is the intuition-level special case: high-pass the fast-but-drifting source (gyro), low-pass the slow-but-stable source (accel gravity), sum. Madgwick/Mahony are principled, efficient versions.

### 3.3 When linear-Gaussian breaks
- **EKF:** linearize a nonlinear system around the current estimate (orientation, GPS trilateration are nonlinear) — works, but can diverge if linearization is poor.
- **UKF:** propagate a set of sample points through the nonlinearity — better than EKF for strong nonlinearities.
- **Particle filter:** represent the belief as thousands of weighted samples — handles *non-Gaussian, multimodal* beliefs (the indoor "could be in room A or room C" ambiguity, Ch 1.7) and hard constraints (can't walk through walls). Expensive but general.
- **Choosing:** linear-Gaussian → KF; mild nonlinearity → EKF; strong → UKF; multimodal/constrained → particle filter. RAXHA's orientation uses complementary/Madgwick; GPS+inertial uses (E)KF; indoor PDR+radio uses particle filters.

### 3.4 The two jobs fusion does for RAXHA
1. **Continuity (filling gaps):** when GPS drops in a tunnel, dead reckoning (accel+gyro) propagates position; when PPG is corrupted by motion, the accel *is* the motion reference. Fusion covers each sensor's blind spots with another's sight.
2. **Contradiction resolution (the intelligence):** when sources disagree, fusion doesn't pick one — it reasons about *which* is more trustworthy *right now*. This is where the treadmill example lives (§8).

---

## 4–8. Working, Data, Algorithms (integrated, RAXHA-specific)

**The fusion stack RAXHA actually runs:**
- **Orientation fusion** (accel+gyro+mag → attitude): complementary/Madgwick/Mahony or platform-provided (`CMDeviceMotion.attitude`, Android rotation vectors). Feeds posture (upright vs lying — the fall confirmer).
- **Position fusion** (GPS+inertial+Wi-Fi/BLE → location+velocity): (E)KF loosely/tightly coupled; dead reckoning through outages (Ch 1.6/1.7). Feeds context + alert payload.
- **Physiological fusion** (PPG+accel → motion-robust HR; HR+HRV+baseline → physiological state): signal-level + baseline modeling (Ch 1.8/1.10).
- **Activity fusion** (IMU features + context → activity state): the HAR layer (C9).
- **Decision-level state fusion** (all of the above + their uncertainties → **human-state estimate**): the top of the graph, feeding Risk Scoring.

**Confidence propagation is the connective tissue:** every stage outputs (estimate, covariance/confidence, timestamp). Fusion is fundamentally *uncertainty arithmetic* — the formal machinery behind Decision #13 ("absence of evidence ≠ evidence of absence" becomes "high covariance = represented uncertainty, not a default-normal assumption").

**Timestamp alignment is a prerequisite, not a detail** (B5): fusing sources on mismatched clocks produces confident garbage (the 600 ms-stale-HR example). Fusion assumes a common, normalized timeline.

---

## The treadmill example — contradiction resolution, formalized

Your canonical case (seed material): **HAR says "running," GPS says "at home, stationary."** A naive system either believes the accelerometer (→ false "emergency exertion") or the GPS (→ misses real running). Fusion instead reasons:
- Both sources are *individually plausible* but *jointly contradictory*.
- Prior knowledge: you can run in place (treadmill) at home; you cannot run 5 km/h across a living room.
- Resolution: **"running-in-place at home" (treadmill workout)** — a *third hypothesis* that reconciles both, with the physiological data (elevated HR consistent with exercise) confirming.
- The output is not "running" or "stationary" but a *fused state* — "exercising, indoors, HR-appropriate, not an emergency" — with quantified confidence.

This is the Competency-1 base-rate problem (spurious "emergency exertion" alarms) solved by cross-modal fusion, and it's why RAXHA fuses rather than thresholds. Generalize it: **a contradiction between two trustworthy sensors is not noise to suppress — it is information about a state neither sensor alone could name.**

---

## 9–12. Products, Research, Security, Medical (brief)

**Products:** every phone/watch fuses IMU for orientation (Madgwick-family), GPS+inertial for navigation, PPG+accel for HR — largely platform-provided (`CMDeviceMotion`, Android rotation vectors, Fused Location). Apple/Google expose *fused* outputs precisely so apps don't hand-roll filters. **Research:** Kalman 1960 (foundational); Madgwick 2010; particle-filter indoor nav; deep/differentiable filtering; multimodal fusion for HAR (Ch C9). **Open problems:** learned+principled hybrid fusion, calibrated uncertainty end-to-end, fusion under adversarial/faulty sensors. **Security:** fusion is a *defense* — cross-sensor consistency detects spoofing (a WALNUT-injected accel signal that gyro/PPG/context don't corroborate is rejected; Ch 1.1/1.2 §11). A fused estimate is harder to attack than any single sensor. **Medical:** fusion is what makes physiological context trustworthy enough for safety decisions (distinguishing exercise tachycardia from pathology needs activity+HR+location fused). Screening-not-diagnosis holds.

## 13. Engineering for RAXHA

1. **Consume platform fusion where it's good** (orientation, location, HR) — don't rebuild Madgwick or Fused Location; RAXHA's differentiated fusion is the **decision-level human-state fusion** at the top.
2. **Every fused estimate carries uncertainty** — the risk engine reasons on (state, confidence), never bare point estimates (Decision #13).
3. **Fusion produces STATE, not ACTION** (Decision #17): the fusion layer outputs "human-state estimate + confidence"; only Risk/Policy convert it to an SOS. Keep the boundary clean.
4. **Contradiction is signal:** design the decision-level fuser to *name reconciling hypotheses* (treadmill), not to pick a winner.
5. **Common timeline first** (B5): normalize timestamps before any fusion.
6. **Graceful degradation:** when a sensor drops, fusion widens uncertainty and leans on the others — never fabricates confidence (the dead-reckoning-with-growing-covariance behavior).
7. **Fusion as spoofing defense:** cross-sensor consistency checks in the fuser reject physically-impossible single-sensor events.

## 14. Failure Analysis

| Failure | Mechanism | Mitigation |
|---|---|---|
| Confident-wrong fused estimate | Overconfident sensor covariance (e.g., optimistic GPS accuracy) | Honest per-sensor uncertainty; robust/outlier-aware filtering |
| Fusion diverges | EKF linearization failure | UKF/particle where nonlinearity is strong; monitor innovation |
| Garbage from clock skew | Fused mismatched timestamps | Normalize timeline first (B5) |
| One bad sensor poisons the estimate | No outlier rejection | Gating/robust fusion; cross-sensor consistency; down-weight implausible |
| Lost track after long outage | Unbounded dead-reckoning drift | Bound coast; re-acquire absolute fixes; represent growing uncertainty |
| Fusion silently overrides a real event | Decision-level fuser treated as authority | Decision #17 — fusion outputs state+confidence, Risk/Policy decide |
| Contradiction discarded as noise | Naive winner-take-all | Reconciling-hypothesis design (treadmill) |

## 15. RAXHA Application — distilled

- **Use as:** the layer that turns nine imperfect witnesses into one trustworthy, uncertainty-quantified human-state estimate — filling blind spots and resolving contradictions.
- **Do NOT use as:** a decision-maker (it estimates state; Risk/Policy act — Decision #17); a black box that hides uncertainty; a consumer of unaligned timestamps.
- **One-liner:** *fusion is where RAXHA stops having nine opinions about the person and starts having one honest, uncertainty-aware understanding of them.*

## 16. Future

Learned + principled hybrid filtering (differentiable Kalman/particle filters); end-to-end calibrated uncertainty; foundation-model fusion (one model ingesting all modalities); on-device federated fusion personalization; robust fusion under sensor faults/attacks. The convergence point: fusion + baselines (C5/C8) + anomaly detection (Module 9) into a single personalized human-state model — the "digital twin of the person" (Module 10).

## 17. Mastery Test — Competency 10

1. Explain the Kalman predict/update cycle and how the Kalman gain embodies "trust each source by its uncertainty." Tie it to the complementary filter and the gated-absolute-reference pattern.
2. When would you choose a particle filter over an EKF for RAXHA, and why (give the indoor example)?
3. Walk through the treadmill contradiction (HAR: running; GPS: home/stationary). How does fusion resolve it, and why is "a contradiction between two trustworthy sensors is information, not noise"?
4. Why must fusion output *state + uncertainty* rather than a bare estimate, and how does that serve Decision #13?
5. Explain why fusion is a spoofing *defense* (tie to WALNUT, Ch 1.1/1.2).
6. Why does fusion produce STATE but not ACTION (Decision #17), and where does the boundary sit?
7. **[Standing gate question]** If RAXHA shipped its decision-level fusion tomorrow, what's the single most likely field failure — scientific, platform, or product?

## 18. Founder Intelligence

**Why hasn't fusion been "solved"?** Low-level fusion (orientation, position, HR) *is* mature and platform-provided — RAXHA shouldn't rebuild it. The *unsolved, differentiated* part is **decision-level human-state fusion with calibrated uncertainty**, personalized per user — nobody ships a great cross-platform version of that, because it requires the whole stack beneath it (the reason this is Competency 10, not 1). **WHOOP/Oura/Garmin/Apple/Google** all fuse their own sensors well; none fuses into a *cross-platform, family-facing, uncertainty-honest human-state estimate*. **Why doesn't everyone build it?** It requires every layer below (sensors→HAR→baselines) done right, plus uncertainty calibration (hard) and real-world validation (slow). **Startup opportunities:** the human-state estimation layer itself as infrastructure; uncertainty-calibrated fusion as licensable IP; multimodal fusion for elder care/clinical. **RAXHA strategy:** fusion is the *integration* moat — the place where RAXHA's nine competencies become one product that no single-sensor competitor can match; it compounds with the personalization/data flywheel. But consume commodity low-level fusion; differentiate at the decision level. **PhD gaps:** calibrated end-to-end uncertainty; learned+principled hybrid fusion; fusion under faulty/adversarial sensors; personalized fusion. **Patents:** Kalman/orientation fusion is old/public; consumer IP is in specific applications (crash detection multi-sensor fusion — Apple; fused location — Google/Qualcomm). Query `multi-sensor fusion emergency detection wearable assignee:X`. **Ledger:** ✅ filter math (public), platform fused APIs, Madgwick (open); 🟡 vendor decision-level fusion; 🔴 competitors' human-state models.

## 19. Design Review (highlights)

- **Chief Scientist:** "Show me your uncertainty is *calibrated* — that a '70% confident' fused state is right 70% of the time. Uncalibrated confidence is worse than none because Risk trusts it."
- **Physician:** "Fusion resolving 'exercise vs emergency' is exactly what makes physiology trustworthy. But prove a *faulty* sensor can't poison the fused estimate into missing a real event."
- **Security researcher:** "Fusion is my favorite defense — a spoofed single sensor should be rejected by cross-consistency. Show the consistency checks."
- **Investor:** "Fusion is where nine features become one product. That integration is the moat single-sensor competitors can't copy quickly. How defensible with the data flywheel?"
- **Architect:** "Confirm fusion outputs state+confidence and never calls the SOS itself (Decision #17). The layer boundary is a safety property."

## 20. Constraint Exercise

Design RAXHA's decision-level human-state fusion for the fall path. Inputs (each with uncertainty): impact (accel), rotation (gyro), posture (orientation fusion), post-event motion (HAR), location/context (GPS+place), physiology (PPG+HR vs baseline). Constraints: output a human-state estimate + calibrated confidence (not an action — Decision #17); a single faulty sensor must not poison the estimate; contradictions must be reconciled not discarded; common timeline assumed. Specify: the fusion approach (per sub-estimate + decision-level), how uncertainty propagates, how you reject a spoofed/faulty sensor, and the exact (state, confidence) handed to Risk Scoring. One-page memo.

## 21. Chief Scientist's Verdict

**Confidence Ledger:** Kalman/complementary orientation & position fusion — ★★★★★ (mature, Apollo-proven). Particle filters for multimodal indoor — ★★★★☆. Signal-level PPG+accel fusion — ★★★★☆ (Ch 1.8). Decision-level human-state fusion with *calibrated* uncertainty — ★★★☆☆ (**the differentiated, harder, less-solved part — RAXHA's real fusion work**). Fusion as spoofing defense — ★★★★☆. Learned/differentiable fusion — ★★★☆☆ (emerging).
**TRL:** Low-level fusion (orientation/position/HR) — 9 (platform). Particle-filter indoor — 6–7. Decision-level calibrated human-state fusion — 4–5 (RAXHA's build). Deep/hybrid fusion — 4–5.
**Roadmap:** *MVP:* consume platform low-level fusion; simple decision-level rule/Bayesian fuser with uncertainty. *V2:* calibrated-uncertainty decision-level fusion, contradiction-reconciliation, spoofing consistency checks. *Research:* learned/hybrid fusion, personalized fusion, end-to-end calibration. *Never Build:* fusion that hides uncertainty; fusion that decides actions (Decision #17); fusion on unaligned timestamps.
**Competitor failures (sourced):** documented sensor-fusion failures in other domains (e.g., aviation/automotive where overconfident or mis-weighted fusion contributed to incidents) — overconfident fusion is *more* dangerous than no fusion because downstream layers trust it; calibration and outlier-rejection are safety-critical. Consumer nav dead-reckoning drift complaints (fused position wandering in tunnels) — bounded coast + honest uncertainty is the lesson.
**Kill Criteria:** if decision-level fusion uncertainty can't be *calibrated* in shadow mode, feed Risk raw per-source estimates with conservative combination rather than a falsely-confident fused number. If a faulty single sensor can poison the fused estimate in testing, add robust/gated fusion before shipping. If fusion complexity doesn't measurably beat simpler cascade rules in real-world validation, ship the simpler version (complexity must earn its confidence).
**Historical Failures (Historian):** the broader history of overconfident automated estimation contributing to accidents (aviation automation-trust incidents) — a fused estimate presented without honest uncertainty invites over-trust; RAXHA's calibration + Decision #17 boundary are the structural defenses. Early robotics/AV programs that over-trusted fusion and failed on edge cases neither sensor covered — fusion fills *known* gaps, not unknown ones; validate on real-world contradictions.

## 22. Knowledge Graph Connections

- **Depends on (prior):** ALL of C1–C9 — fusion is the convergence node. Directly: orientation (C1–4), position (C6–7), physiology (C5, C8), activity (C9), the acquisition timeline (B5), and Decisions #13 (uncertainty), #16 (baselines), #17 (state-not-action).
- **Depended on by (future):** Module 9 Anomaly Detection (operates on fused state + baseline), Context Engine, Risk Scoring, Emergency Decision — everything above.
- **RAXHA subsystem:** the integration layer producing the human-state estimate; feeds Risk Scoring.
- **AI models:** Kalman/EKF/UKF/particle filters; complementary/Madgwick/Mahony (orientation); Bayesian/learned decision-level fusers.
- **Sensors contributing:** all of them — fusion is where the whole sensor stack becomes one estimate.
- **Assumptions for validity:** honest per-source uncertainty; common normalized timeline; outlier/faulty-sensor rejection; calibrated output confidence; fusion estimates, Policy decides.
- **Confidence:** low-level fusion ★★★★★ / calibrated decision-level human-state fusion ★★★ (the build). See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Paired chapter this competency: **B9 — Core ML & On-Device Inference Pipelines** (the Apple-side inference the fused models run on).*
