# SEED — Situational Awareness Layers & Sensor Fusion (forward-reference)

> **Status:** Seed material (user-provided 2026-07-13 + professor annotations). **Not yet a taught chapter.** The rigorous treatment lands at **Competency 10 (Sensor Fusion, Module 8)**, built on the estimation-theory math from Module 2 and the HAR chapter (Competency 9). Captured here so it isn't lost and so later chapters can cross-link to it. Annotations marked **[Prof.]** flag where the preview simplifies something we'll rigorize later.

## The 4 layers of situational awareness (the RAXHA context stack)

| Layer | Role | Sensors / source | Answers |
|---|---|---|---|
| **GPS (Spatial context)** | macro-environment; map coordinates → semantic place (home, gym, highway) | GNSS + Wi-Fi/BLE (Ch 1.6, 1.7) | *Where, and what kind of place?* |
| **Gait (Physical state)** | micro-movement patterns; walking/running/limping/falling | accel + gyro (+ baro) (Ch 1.1–1.4; Competency 8) | *What is the body physically doing?* |
| **HAR (Behavioral intent)** | raw sensor data → specific activity (typing, driving, cooking) | IMU + context (Competency 9) | *What task/behavior is this?* |
| **Sensor Fusion (Intelligence engine)** | resolve contradictions, filter noise, compute one high-confidence truth | all of the above (Competency 10) | *What is actually true, and how sure are we?* |

**[Prof.]** This stack IS the "state + confidence" half of the mission statement ("What is the current state of this human, how confident are we…"). The escalation layer is the "does someone need to know" half.

## How fusion solves the hard problems (worked cases — keep these; they're excellent teaching examples)

1. **Handling contradictions:** GPS says 60 km/h but gait says stationary → fusion concludes *passenger in a vehicle*, not sprinting. **[Prof.]** This is the driving-context gate we already invoked in Ch 1.1/1.2/1.6 for false-alarm suppression — now formalized.
2. **Filling coverage gaps:** GPS drops in a subway → fusion uses inertial **dead reckoning** to estimate distance walked underground. **[Prof.]** Precisely: dead reckoning is *inertial* (accel step-count + gyro/mag heading); gait supplies the step model. The GPS-indoor-blindness problem from Ch 1.6 §3.3 gets its answer here + in Ch 1.7.
3. **Contextual filtering (the base-rate killer):** HAR detects a "running" signature but GPS shows the user is *at home* → fusion differentiates a real emergency from an **indoor treadmill workout**. **[Prof.]** This is the single best illustration in the whole curriculum of why context beats any single sensor — it's the Competency-1 base-rate lesson (302 false alarms/week) solved by cross-modal context. Treadmill-at-home is now the canonical RAXHA context-fusion example.

## Common fusion approaches (preview — rigorized in Competency 10)

- **Kalman filters (and EKF/UKF):** blend GPS + inertial by predict-then-update, weighting each source by its reported accuracy. **[Prof.]** The accuracy-weighting is exactly the "accuracy is a field, propagate it" rule from Ch 1.6 §7. Deep dive: linear KF → EKF → UKF → particle filter, plus the complementary/Madgwick/Mahony filters previewed in Ch 1.3/1.4 §8.
- **Deep learning (RNNs / Transformers):** ingest multi-stream time series simultaneously to classify complex behavior. **[Prof.]** Ties to the HAR deep-model lineage (DeepConvLSTM → transformers/SSL) from Ch 1.1 §8/§10; the scarce-label problem (real falls are rare) makes self-supervised pretraining central.
- **Hidden Markov Models:** model the most likely *sequence* of activities given location + movement history. **[Prof.]** Good for HAR temporal smoothing; also foreshadows change-point detection and the anomaly-detection module (Module 9).

## Fusion taxonomy to teach at Competency 10 (not in the user's note — professor's addition)
- **Early / data-level fusion** (raw signals combined) vs **feature-level fusion** (per-sensor features concatenated) vs **late / decision-level fusion** (per-sensor decisions combined). RAXHA's cascade already mixes these: PPG+accel fuse at the *signal* level (motion reference, Ch 1.8), while location/activity fuse at the *decision* level (context gating).
- **Confidence propagation** is the connective tissue: every layer outputs (estimate, uncertainty), and fusion is fundamentally uncertainty arithmetic — the formal version of Decision #13.
