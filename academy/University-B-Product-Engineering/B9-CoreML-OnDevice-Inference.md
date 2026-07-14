# Chapter B9 — Core ML & On-Device Inference Pipelines

> **Paired with:** Competency 10 (Sensor Fusion). Fusion produces the models and estimates; this chapter is how they *execute* on Apple hardware specifically — the counterpart to B8's bare-metal/TinyML/Android story. Core ML is Apple's high-level on-device inference framework, and it's where RAXHA's Apple-side risk engine actually runs, on the Neural Engine, at low power, never touching the cloud (Doctrine #2). Taught under the Principal Architect contract; heavy platform-truth (Doctrine #12 — re-verify against current docs).

---

## 1. Why Core ML exists

Running a neural net on a phone naively (raw CPU, float, no acceleration) is slow and battery-hostile. **Core ML** (Apple, 2017) is the abstraction that runs models efficiently across Apple's compute units — **CPU, GPU, and the Apple Neural Engine (ANE)** — choosing the best automatically, with the model compiled and optimized for the specific device. For RAXHA it's the sanctioned, high-performance, low-power path to on-device inference on iPhone and Apple Watch — the Apple-hardware realization of the TinyML principles from B8.

Core ML vs TFLM (B8): TFLM is bare-metal, portable, you-manage-everything, ideal for MCUs and on-sensor cores; **Core ML is higher-level, Apple-hardware-optimized, ANE-accelerated** — the right tool *on Apple devices*. RAXHA uses both: on-sensor MLC (Tier-0) and TFLM/Core ML at Tier-1/2 depending on platform.

---

## 2. The Apple Neural Engine and compute units

- **ANE:** a dedicated NPU for neural inference — massively parallel, extremely energy-efficient for supported ops (orders of magnitude better perf/watt than CPU). For an always-on safety confirmer, running on the ANE means inference is nearly free energetically.
- **`MLComputeUnits`:** you can hint `.all` (CPU+GPU+ANE), `.cpuAndNeuralEngine`, `.cpuOnly` — trade determinism/compatibility vs performance. Not every op maps to the ANE; unsupported ops fall back to GPU/CPU (a performance cliff to profile for).
- **Watch reality:** Apple Watch has constrained compute vs iPhone; validate that the model runs within the watch's envelope, not just the phone's (the B8 "validate on the actual target" rule).

## 3. The Core ML pipeline

- **Model conversion:** train in PyTorch/TensorFlow → convert with **`coremltools`** to the `.mlmodel`/`.mlpackage` format → compiled on-device to `.mlmodelc`. Quantization (int8/float16), palettization, and pruning are supported in-conversion (the B8 techniques, Apple-side).
- **Create ML:** Apple's train-on-Mac tool for common tasks (including activity classification from Core Motion data — directly relevant to HAR/fall models) — a fast path for RAXHA's simpler classifiers.
- **Integration frameworks:** Core ML underpins **Vision** (image), **Sound Analysis** (audio — relevant to crash-acoustics), **Natural Language**, and works directly on **Core Motion** tensors for HAR. RAXHA's motion models take windowed IMU tensors → Core ML → (label, confidence).
- **On-device personalization:** Core ML supports **on-device model updates** (`MLUpdateTask`) — fine-tuning a model on the user's own data *on the device*, never uploading it. This is the Apple-native mechanism for Doctrine #16 (personalize) + privacy (no raw-data egress) + federated-style learning. A genuinely strategic capability for RAXHA's personal-baseline models.

## 4. Latency, battery, security, failure

- **Latency:** ANE inference is milliseconds — inside the <100 ms budget (Doctrine §3) with room to spare; the confirmer's inference cost is negligible vs sensor warm-up and the deliberate countdown.
- **Battery:** ANE perf/watt is the whole point — always-on-ish confirmation becomes affordable. Still event-gated (Tier-0 triggers Tier-1), still measured.
- **Security:** **Core ML model encryption** (Apple supports encrypted models, decrypted only in-memory at load) protects model IP on-device; models delivered/updated via a signed, versioned pipeline (control plane, B1). On-device personalization means the *personalized* model and the raw data never leave the device — a privacy property, not just performance.
- **Failure modes:**

| Failure | Cause | Defense |
|---|---|---|
| ANE fallback to CPU tanks perf/battery | Unsupported ops in the model | Design to ANE-supported ops; profile compute-unit usage; validate on-device |
| Model great on iPhone, fails on Watch | Compute envelope differs | Validate on Apple Watch specifically (B8 target-validation rule) |
| int8/float16 accuracy loss on fall class | Quantization in conversion | Validate the converted model on the rare class (B8), not float |
| Personalized model drifts wrong | On-device update on bad/biased local data | Guard personalization; keep a population fallback; bound adaptation |
| Silent regression after model update | Unvalidated OTA model | Signed, canaried, shadow-tested model releases (B1/B8) |
| Preprocessing skew | Core Motion preprocessing differs train↔device | Identical preprocessing pipeline; test device outputs vs reference |

## 5. RAXHA production shape (Apple side)

- **`CoreMLEngine`** implements the pure core's `Inference` interface (B8) — the risk engine calls `classify(window)`; Core ML/ANE is hidden behind it.
- **Model registry + signed OTA** (shared control plane with Android/TFLM): one model-release discipline, two runtime targets.
- **On-device personalization module** (`MLUpdateTask`): per-user fine-tuning of baseline/HAR models, on-device only, with a population fallback and bounded adaptation — Doctrine #16 realized on Apple hardware.
- **Shared preprocessing** with training (the B8 skew defense) and with the Android path (one feature-extraction spec, both platforms).
- **Replay CI** validates the *converted, quantized* Core ML model on real-world traces (B1/B8), on-device where possible.

## 6. Founder Intelligence

**Strategic reading:** Core ML + ANE + on-device personalization is Apple handing RAXHA exactly the infrastructure its doctrine requires (on-device, private, low-power, personalizable) — the moat isn't the runtime (everyone on Apple has Core ML) but the *models* (real-world fall-data flywheel, C9) and the *personalization discipline*. **On-device personalization (`MLUpdateTask`) is a strategic unlock:** RAXHA can personalize per-user (Doctrine #16) with zero raw-data egress — a privacy differentiator that's also a Sherlocking hedge (the personalization IP is portable). **Platform risk (recurring):** Apple could deepen native health-model capabilities; RAXHA's defense is the cross-platform response layer + data flywheel, not the inference runtime. **Ledger:** ✅ Core ML/ANE/coremltools/MLUpdateTask capabilities; 🟡 exact ANE op support per chip (profile it); 🔴 Apple's own health-model internals. **Kill-relevant:** if the fall confirmer can't hit ANE-supported-ops + watch-envelope + rare-class-accuracy simultaneously, the always-on Apple-watch promise narrows — a product-scope decision driven by Core ML constraints (mirrors B8).

## 7. Design Review (highlights)

- **Chief Scientist:** "Validate the *converted, quantized, on-Watch* model on real-world falls — three transformations from your training model, each can wreck the rare class."
- **Battery reviewer:** "Confirm the model runs on the ANE, not falling back to CPU. Show compute-unit profiling and µJ/inference on the Watch."
- **Privacy advocate:** "On-device personalization is a strong privacy story — prove the personalized model and raw data never leave the device, even for 'improvement.'"
- **SRE:** "Model updates are safety deploys. Signed, canaried, shadow-tested, rollback — same pipeline as Android, one discipline."

## 8. Constraint Exercise

Deploy RAXHA's fall confirmer + personalized baseline model to Apple Watch via Core ML. Constraints: run on the ANE (not CPU fallback), fit the Watch compute/memory envelope, int8/float16 with rare-class accuracy preserved, on-device personalization with population fallback and no raw-data egress, and a signed/shadow-tested update path shared with the Android build. Specify: the conversion + quantization approach, how you keep ops ANE-supported, the personalization design (and its guards), the on-Watch validation, and the shared model-release pipeline. One-page memo.

## 9. Chief Scientist's Verdict

**Confidence Ledger:** Core ML/ANE as production on-device inference — ★★★★★. On-device personalization (`MLUpdateTask`) with no data egress — ★★★★☆ (supported; needs careful guards). "ANE gives near-free perf/watt for supported ops" — ★★★★★. "Unsupported ops silently fall back and tank perf" — ★★★★☆ (profile-dependent). Core ML model encryption protecting on-device model IP — ★★★★☆.
**TRL:** Core ML/ANE inference — 9. coremltools conversion + quantization — 9. On-device personalization — 7–8 (supported; RAXHA guards to build). Watch-envelope validated safety model — 7. Shared cross-platform model-release pipeline — 7.
**Roadmap:** *MVP:* Core ML fall/HAR confirmer on iPhone/Watch (ANE), signed updates. *V2:* on-device personalized baselines (`MLUpdateTask`), encrypted models, richer Tier-2. *Research:* on-device continual learning. *Never Build:* cloud-gated inference; unsigned model updates; personalization that egresses raw data; shipping a model validated only on iPhone/float.
**Competitor failures (sourced):** documented ANE-fallback performance surprises (developer reports of models silently running on CPU) — "it uses Core ML" doesn't mean "it uses the ANE"; profile it. The general on-device-personalization risk of models drifting on biased local data (a known ML pitfall) — guard with population fallback and bounded adaptation.
**Kill Criteria:** if the model can't stay on ANE-supported ops within the Watch envelope at rare-class accuracy, narrow the always-on Apple promise to iPhone-present or armed modes. If on-device personalization can't be guarded against local-data drift, ship population models + conservative personalization only. If model-update safety can't be guaranteed, pin models to app releases.
**Historical Failures (Historian):** the broader "on-device AI" gap between marketing and profiled reality (models not actually accelerated, or too big for the target) — validate on the real device, not the simulator. Safety-model deployment failures across regulated industries — why Core ML model updates get firmware-grade release discipline (shared with B8).

## 10. Knowledge Graph Connections

- **Depends on (prior):** C10 fusion + C9 HAR (the models), B8 TinyML (quantization/deployment principles), B2 (Apple stack), Doctrine #2 (on-device), #12 (platform truth), #16 (personalize).
- **Depended on by (future):** Module 9 anomaly-detection models on Apple devices; the Apple-side Risk Engine; every Apple-platform inference.
- **RAXHA subsystem:** the Apple-side on-device inference layer of the risk engine (Tier-1/2).
- **AI models:** Core ML–compiled fall/HAR/baseline models on ANE; on-device personalized variants.
- **Sensors contributing:** runs on ANE/GPU/CPU; consumes Core Motion / HealthKit-derived features.
- **Assumptions for validity:** ANE-supported ops; validated on-Watch + quantized + rare-class; personalization guarded; signed/shadow-tested updates; no raw-data egress.
- **Confidence:** Core ML/ANE ★★★★★ / guarded on-device personalization ★★★★. See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Competency 11 pairing: **Module 9 — Personalized Anomaly Detection** + **B10 — Backend: alert delivery, push, telephony, live location**. The stack now has a fused, personalized human-state estimate; anomaly detection is where "change from baseline" (Decision #16) becomes the detector, and the backend is where a decision finally becomes a delivered alert.*
