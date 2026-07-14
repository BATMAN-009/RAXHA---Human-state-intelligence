# University B — Product Engineering Curriculum

**Purpose:** Learn how Apple, Google, and Garmin *actually build* products around sensors. University A teaches what the accelerometer does; University B teaches how to wrap Apple-level software around it.

**Method:** Same rules as University A — one chapter per week, textbook depth, mastery test gates progression. Each B-chapter is paired with the A-chapter taught the same week, so theory becomes implementation immediately.

---

## Competency progression (paired)

> Progress is measured in **competencies**, not weeks. Each competency = one A chapter + one B chapter + passed gate, and carries four objective classes: **learning** (can explain it), **engineering** (can build/debug it), **founder** (can decide with it — §18–20 of each chapter), **research** (knows what's unsolved). Completion criterion: the mastery gate, answered in the learner's own words.

| Competency | University A (Science) | University B (Engineering) | Status |
|------|------------------------|----------------------------|--------|
| 1 | 1.1 Accelerometer | **B1 Software Architecture for Sensing Platforms** | ✅ PASSED (2026-07-13) |
| 2 | 1.2 Gyroscope | B2 Swift & the Apple development stack | ✅ PASSED (2026-07-13) |
| 3 | 1.3–1.4 Magnetometer, IMU & calibration | B3 Kotlin & the Android/Wear OS stack | ✅ PASSED (2026-07-13) |
| 4 | 1.8 PPG | B4 HealthKit & Health Connect | ✅ PASSED (2026-07-13) |
| 5 | 1.10 HR & HRV | B5 Core Motion & Android Sensor APIs in production | ✅ PASSED (2026-07-13) |
| 6 | 1.6 GPS/GNSS | B6 Location services, geofencing & background execution | ✅ PASSED (2026-07-13) |
| 7 | 1.7 Wi-Fi/BT/UWB/indoor positioning, geofencing | B7 Bluetooth LE & watch↔phone communication | ✅ PASSED (2026-07-13) |
| 8 | **Human Gait Intelligence** (standalone; engineering woven into chapter §13) | *(no separate B chapter — standalone by design)* | ✅ PASSED (2026-07-13) |
| 9 | HAR (Module 7) | B8 TinyML deployment (TF Lite Micro, on-sensor ML) | ✅ PASSED (2026-07-13) |
| 10 | Sensor Fusion (Module 8) | B9 Core ML / on-device inference pipelines | ✅ PASSED (2026-07-13) |
| 11 | Personalized Anomaly Detection (Module 9) | B10 Backend: alert delivery, push, telephony, live location | ✅ PASSED (2026-07-13) |
| 12 | Context Awareness + Risk Scoring → Emergency Decision | B11 Security engineering (Keychain/Keystore, E2E encryption, TEE) | ✅ Written — gate open |
| 13 | Privacy-Preserving AI (federated learning, DP, secure aggregation) | B12 Testing, release engineering & fleet observability | ✅ Written — gate open |
| 14 | Digital Biomarkers & Digital Phenotyping (Module 10) | B13 Architecture patterns (MVVM, Clean/Hexagonal, SOLID, DDD, DI, offline-first) | ✅ Written — gate open |
| 15 | Medical AI, Clinical Validation & Regulatory (Module 16) — FINALE | B14 Medical-Device Software Engineering & Regulatory Quality | ✅ Written — gate open (LAST core-arc gate) |
| 9 | Anomaly Detection (Module 9) | B9 Core ML / on-device inference pipelines | — |
| 10 | Emergency Detection (Module 11) | B10 Backend: alert delivery, push, telephony, live location | — |
| 11 | Privacy & Security (Module 13) | B11 Security engineering: Keychain/Keystore, E2E encryption, TEE | — |
| 12 | Medical AI & validation (Module 16) | B12 Testing, release engineering & fleet observability (CI/CD, crash reporting) | — |
| 13 | — | B13 Architecture patterns: MVVM, Clean/Hexagonal Architecture, SOLID, DDD, dependency injection, offline-first & state management | — |
| 14 | — | B14 API & communication design: REST, gRPC, WebSockets, contract design | — |
| 15 | — | B15 Event-driven backend: event sourcing, CQRS, queues, Kafka, Temporal orchestration | — |
| 16 | — | B16 AuthN/AuthZ & applied encryption for the RAXHA backend | — |

**Where the requested coding topics live:**
- *Mobile:* Swift/SwiftUI → B2; Kotlin/Compose → B3; MVVM, Clean Architecture, DI, offline-first, state management → B13; background execution & battery optimization → threaded through B2–B6.
- *Backend:* REST/gRPC/WebSockets → B14; PostgreSQL/Redis → B10; event-driven, CQRS, event sourcing → B15; auth & encryption → B16 (+ B11).
- *AI:* TF Lite/TinyML → B8; Core ML/ONNX/edge inference/model optimization → B9; time-series models → University A Modules 6–9.
- *Signal processing:* FFT, low/high-pass, Butterworth, Kalman, DSP, feature engineering → **University A Module 3** (the math/science home), with implementation exercises in B8/B9.
- *Software engineering:* SOLID/DDD/Clean Code/Hexagonal → B13; microservices → B15; testing/CI-CD/crash reporting/observability → B12.

**Governing document:** [01-ENGINEERING-DOCTRINE.md](../01-ENGINEERING-DOCTRINE.md) — native-first, on-device risk engine, no LLM in the detection path, latency budget, architecture-before-code. Every B chapter is taught under the Principal Software Architect role contract defined there.

**Current position:** Competencies 1–3 PASSED (2026-07-13). Competency 4 (PPG + HealthKit/Health Connect) written, gate open. Chapter template complete at §1–21 (§21 has 6 subsections incl. Historian). Every gate now ends with the standing "most likely failure if shipped tomorrow" question (AQ-2, ratified).

---

## B-track principles (apply to every chapter)

1. **Native first.** A sensor-heavy, background-running, battery-critical safety app cannot be built well in cross-platform frameworks. Swift/watchOS and Kotlin/Wear OS are non-negotiable core skills.
2. **The OS is your adversary and your ally.** Half of B-track content is learning what the platform *forbids* (background limits, Doze, watchOS lifecycle) and the sanctioned escape hatches (hub offload, batching, platform detectors, push wakeups).
3. **Reliability is the product.** RAXHA's feature is a promise: "if it happens, the alert arrives." Every B chapter connects to delivery guarantees, failure handling, and observability.
4. **Study shipping products.** Each chapter dissects how Apple/Google/Garmin implement the equivalent layer, labeled verified vs inferred, same as University A.
