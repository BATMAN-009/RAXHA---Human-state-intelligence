# Chapter B8 — TinyML Deployment

> **Paired with:** Competency 9 (HAR). That chapter designed the models; this one makes them *run in kilobytes of RAM, on microamps, on the watch* — because RAXHA's whole architecture (the always-on Tier-1 confirmer of B1) depends on inference that costs almost no power and never needs the cloud. TinyML is where "on-device risk engine" (Doctrine #2) stops being an aspiration and becomes a memory budget. Taught under the Principal Architect contract.

---

## 1. Why TinyML exists

Normal ML assumes gigabytes of RAM, a GPU, and wall power. A microcontroller (the watch's always-on core, or the sensor hub) has **kilobytes to a few megabytes of RAM, no GPU, no OS sometimes, and a battery measured in days.** TinyML is the discipline of running neural networks in that envelope — models of 10–250 KB, integer arithmetic, microjoules per inference. It exists because the alternative (stream sensor data to the cloud for inference) is *fatal* to RAXHA on three axes at once: **latency** (network round-trip blows the <500 ms budget), **power** (the radio is the most expensive thing on the device — Ch 1.1/1.6), and **privacy + availability** (Doctrine #2: the SOS decision must not depend on connectivity, and raw biometric data must not leave the wrist).

So TinyML is not an optimization for RAXHA — it is *load-bearing architecture*. The Tier-0/Tier-1 confirmer (B1) is a TinyML model by necessity.

---

## 2. The core techniques (how a model becomes tiny)

- **Quantization:** convert 32-bit float weights/activations to **int8** (or lower) → 4× smaller, faster integer math, dramatically less energy, with usually-small accuracy loss. **Post-training quantization** (quick) vs **quantization-aware training** (train with quantization simulated → better accuracy at int8). This is the single highest-leverage TinyML technique.
- **Pruning:** remove near-zero weights/connections → sparser, smaller model.
- **Knowledge distillation:** train a small "student" to mimic a large "teacher" → the student punches above its size.
- **Architecture choice:** small-by-design nets (depthwise-separable convolutions à la MobileNet; tiny 1D-CNNs for time series; small GRUs) rather than shrinking a huge model.
- **Operator/memory budgeting:** the runtime pre-allocates a fixed "tensor arena"; you design to a hard RAM ceiling (there is no malloc-your-way-out on an MCU).

The RAXHA relevance: the HAR/fall confirmer (Competency 9) becomes an int8 1D-CNN of tens of KB, running in a fixed arena on the watch MCU, invoked only when Tier-0 fires — microjoules per inference, no radio, no cloud.

---

## 3. The runtimes

- **TensorFlow Lite for Microcontrollers (TFLM):** the reference bare-metal runtime — no OS, no dynamic allocation, a C++ interpreter with a fixed tensor arena; runs on Cortex-M and similar. The archetype for on-sensor/on-MCU inference.
- **Core ML (Apple):** compiles models to run on the **Apple Neural Engine (ANE)** / GPU / CPU on iPhone and Apple Watch — the sanctioned high-level path on Apple hardware (this is B9's deep dive; TFLM is more the bare-metal/Android/on-sensor story).
- **ONNX Runtime / LiteRT / ExecuTorch:** cross-platform on-device inference.
- **Vendor NPU/DSP SDKs:** Qualcomm AI Engine (Hexagon DSP), and — crucially for RAXHA — **on-sensor ML cores**: **ST's MLC (Machine-Learning Core)** and **Bosch's smart-hub (BHIxxx)** run decision-tree/small-model inference *inside the IMU package* at µA. This means part of RAXHA's Tier-0 can literally live in the accelerometer chip (Ch 1.1 §13).
- **Wear OS / Android:** LiteRT (TF Lite) with NNAPI/vendor delegates.

## 4. The tiered inference architecture (where each model runs)

TinyML makes the cascade (Ch 1.1 §8 / B1) physical:
```
Tier 0  on-sensor ML core (ST MLC / Bosch)   ~µA   decision stump / tiny model: "impact-like? move?"
Tier 1  watch MCU / ANE (TFLM / Core ML)     ~mJ   int8 CNN fall/HAR confirmer on the buffered window
Tier 2  phone (Core ML / LiteRT, NPU)        ~mW   richer context-fusion model (location+HR+activity)
Tier 3  cloud (optional, NEVER gating)       —     heavy models for post-hoc analysis / fleet learning
```
Each tier is smaller-cheaper-dumber below, bigger-costlier-smarter above; each only runs when the tier below fires. **The SOS decision lives at Tier 1/2 — on-device — always** (Doctrine #2). The cloud never gates.

## 5. Latency, battery, security, failure — the four lenses

- **Latency:** on-MCU int8 inference is sub-millisecond-to-milliseconds — trivially inside the <100 ms inference budget (Doctrine §3). The point of TinyML is that inference latency essentially disappears; the budget is spent elsewhere (sensor warm-up, deliberate countdown).
- **Battery:** microjoules/inference, and — critically — **no radio**. A cloud inference costs ~100–1000× the energy of a local one once you count the transmit. This is the whole power argument for the edge.
- **Security/privacy:** on-device inference means raw sensor data never leaves the wrist (Doctrine #5, data plane) — TinyML is a *privacy* technology as much as a power one. Model theft/extraction is a threat (an attacker with the device can read the model) → don't put secrets in models; sign model updates (control plane, B1); the *decision* is what matters, not model confidentiality.
- **Failure modes:**

| Failure | Cause | Defense |
|---|---|---|
| Accuracy collapses at int8 | Post-training quantization on a sensitive model | Quantization-aware training; per-channel quant; validate int8 model, not just float |
| Model won't fit the arena | Underestimated RAM | Design to the RAM ceiling; profile the tensor arena; prune/distill |
| Silent model regression after update | Unvalidated control-plane push (recall B1) | Signed, canaried, shadow-tested model rollouts; on-device A/B |
| Float/int mismatch bugs | Preprocessing differs train vs device | Identical preprocessing pipeline train↔device; test on-device outputs vs reference |
| On-sensor model too limited | MLC only does simple models | Use it for Tier-0 gating only; real confirmation at Tier-1 |
| Drains battery anyway | Model runs continuously | Event-gated invocation (Tier-0 triggers Tier-1); duty-cycle; measure µJ/inference |

## 6. RAXHA production shape

- **`Inference` interface** in the pure core; `CoreMLEngine` (Apple), `LiteRTEngine` (Android/Wear), `OnSensorMLC` (IMU core) implement it — the risk engine calls `classify(window) → (label, confidence)` and never sees the runtime (the B2/B3 purity rule, now for ML).
- **Model registry + signed OTA updates** (control plane, B1): versioned models, staged rollout, shadow mode before live, rollback. A bad safety model is a recall-class event — treat model deployment with the seriousness of firmware.
- **Identical preprocessing** shared between training and the on-device path (the same feature code, ideally the same source) — preprocessing skew is the classic silent TinyML bug.
- **The replay harness (from B1) now validates the *quantized* model:** recorded fall traces → int8 on-device inference → assert outcome, in CI, on the actual target where possible.
- **Confidence out, not just label:** the model emits calibrated confidence so the risk engine can apply Decision #13 (low confidence → widen, don't silence).

## 7. Founder Intelligence

**Strategic reading:** TinyML is what makes RAXHA's core doctrine (on-device risk engine, no cloud gating, privacy-preserving, battery-viable) *physically possible* — it's not a feature, it's the enabling constraint the whole company is built on. **Why incumbents are strong here:** Apple's ANE + Core ML and on-sensor ML cores (ST/Bosch) are mature; RAXHA *composes* them, doesn't rebuild them. **The moat isn't the runtime** (everyone has TF Lite / Core ML) — it's the *models* (trained on the real-world fall-data flywheel, Competency 9) and the *deployment discipline* (signed, shadow-tested, personalized). **On-sensor ML** is a strategic unlock: pushing Tier-0 into the IMU package means always-on safety at µA, extending battery and enabling the "always protected" promise. **Ledger:** ✅ TFLM/Core ML/MLC capabilities, quantization methods; 🟡 vendor NPU performance specifics; 🔴 competitors' on-device model architectures. **Kill-relevant:** if the fall confirmer can't hit target accuracy at a size/power that fits the always-on budget, the always-on promise narrows (armed-modes only) — a product-scope decision driven by a TinyML constraint.

## 8. Design Review (highlights)
- **Chief Scientist:** "Show me the *int8* model's real-world metrics, not the float model's. Quantization can quietly wreck a sensitive fall classifier — validate what actually ships."
- **Battery reviewer:** "µJ per inference and invocations per hour, measured on-device. 'It's TinyML so it's free' is not a number."
- **SRE:** "Model updates are safety-critical deploys. Signed, canaried, shadow-tested, rollback-able. Show me the model-release pipeline, not just the training notebook."
- **Security researcher:** "An attacker can extract the on-device model. Confirm nothing secret is in it and updates are signed so they can't push a malicious model."
- **Privacy advocate:** "On-device inference is your privacy story — make sure raw windows truly never leave, even for 'model improvement,' without explicit opt-in."

## 9. Constraint Exercise
Deploy the fall confirmer to the Apple Watch and a mid-range Wear OS watch. Constraints: <50 KB model, int8, <10 ms inference, µJ-scale energy, invoked only on Tier-0 trigger, identical preprocessing train↔device, and a signed shadow-tested update path. Specify: the architecture and quantization approach, how you validate the int8 model on real-world (not lab) falls, how it's invoked in the cascade, the update/rollback pipeline, and the on-device metrics you'd instrument. One-page memo.

## 10. Chief Scientist's Verdict
**Confidence Ledger:** int8 quantization with QAT preserving accuracy for HAR/fall models — ★★★★☆. TFLM/Core ML/MLC as production on-device runtimes — ★★★★★. On-sensor ML cores running Tier-0 gating at µA — ★★★★☆ (shipped in ST/Bosch parts). "On-device inference is ~100–1000× more energy-efficient than cloud once radio counts" — ★★★★★. "Quantization can silently degrade sensitive classifiers" — ★★★★★ (validate int8, not float).
**TRL:** TFLM/Core ML/LiteRT deployment — 9. int8 HAR/fall models on-watch — 8. On-sensor MLC Tier-0 — 8. Signed shadow-tested model OTA for safety — 7 (standard MLOps, needs building rigorously). Personalized/federated on-device models — 5–6.
**Roadmap:** *MVP:* int8 fall confirmer on watch (TFLM/Core ML) + on-sensor Tier-0 gating; signed model updates. *V2:* personalized on-device models, federated updates, richer Tier-2 phone models. *Research:* on-device continual learning. *Never Build:* cloud-gated inference for the SOS decision; unsigned model updates; shipping a float-validated model as int8 without revalidation.
**Competitor failures (sourced):** the general MLOps failure genre of unvalidated model deploys causing silent production regressions (widely documented across the industry) — for a safety model this is a recall-class event, hence signed+canaried+shadow. Documented cases of quantized models losing accuracy on rare classes (the fall class is exactly the vulnerable one) — validate the shipped artifact on the rare class, not aggregate accuracy.
**Kill Criteria:** if the int8 confirmer can't meet real-world fall recall at the always-on size/power budget, narrow the always-on promise to armed modes and run the bigger model there. If model-update safety (signing/shadow/rollback) can't be guaranteed, don't ship OTA model updates — pin models to app releases. If on-device personalization needs raw-data egress, do federated or don't personalize.
**Historical Failures (Historian):** the broader edge-AI hype vs reality gap (many "AI on device" products underdelivered on accuracy at the tiny-model scale) — TinyML is real but has hard accuracy/size limits; design within them, don't wish them away. Safety-critical software update failures across industries (bad OTA bricking or mis-behaving devices) — why RAXHA treats model deployment with firmware-grade seriousness.

## 11. Knowledge Graph Connections
- **Depends on (prior):** Competency 9 HAR (the models deployed here), B1 (tiers + control-plane model updates), B2/B3 (on-device execution), Doctrine #2 (on-device risk engine), #5 (data plane).
- **Depended on by (future):** B9 Core ML deep dive; Module 9 anomaly detection (on-device anomaly models); every Tier-0/1 inference in production.
- **RAXHA subsystem:** the on-device risk engine's inference layer (Tier-0 on-sensor, Tier-1 watch, Tier-2 phone).
- **AI models consuming/embodying it:** quantized CNN/GRU fall & HAR confirmers; on-sensor decision models; (future) personalized/federated models.
- **Sensors contributing:** runs on IMU-core/MCU/NPU; consumes accel/gyro/HR features.
- **Assumptions for validity:** int8 model validated on real-world data (not just float); identical train↔device preprocessing; signed/shadow-tested updates; event-gated invocation.
- **Confidence:** runtimes ★★★★★ / int8 accuracy preservation ★★★★ / safety-grade model OTA ★★★★. See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Competency 10 pairing: **Sensor Fusion** (Module 8) — where all the state estimates, each with its uncertainty, finally combine into one high-confidence human-state truth (the seed at [SEED-situational-awareness-layers.md](../Module-08-Sensor-Fusion/SEED-situational-awareness-layers.md) becomes a full chapter).*
