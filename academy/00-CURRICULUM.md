# RAXHA Mastery Curriculum — University A (Science)

**Goal:** Graduate-level and industry-level mastery of every domain required to build RAXHA — an automatic, context-aware personal-safety platform running on the smartwatch and phone people already carry.

**Two parallel universities:**
- **University A (this file):** understand the science — sensors, physiology, ML, fusion, detection.
- **University B ([B0-CURRICULUM.md](University-B-Product-Engineering/B0-CURRICULUM.md)):** learn how Apple/Google/Garmin actually build products — architecture, Swift/Kotlin, HealthKit, Core Motion, TinyML/CoreML, backend. Each week pairs one A chapter with one B chapter so theory immediately becomes implementation.

**Method:** One topic at a time. Each topic becomes a standalone chapter in this knowledge base, taught in the fixed 17-section format (Definition → History → Science → Internal Working → Hardware → Software → Data → Algorithms → Real Products → Research → Security → Medical → Engineering → Failure Analysis → RAXHA Application → Future → Mastery Test). We do not advance until the mastery test is passed.

---

## Module progression

| # | Module | Status |
|---|--------|--------|
| 1 | **Sensor Fundamentals** (motion → location → health → environmental → proximity → audio → camera) | ⏳ IN PROGRESS |
| C8 | **Human Gait Intelligence** (standalone competency; user-directed 2026-07-13) — bridge from physiology → HAR; 3 domains: Clinical Gait Analysis / Behavioral Gait Intelligence / Gait Recognition & Privacy. Chapter: [C8-Human-Gait-Intelligence.md](Module-04-Biomechanics/C8-Human-Gait-Intelligence.md) | ✅ Written — gate open |
| 2 | Mathematics for sensing & AI (linear algebra, probability, DSP math, estimation theory) | — |
| 3 | Signal processing (filtering, spectral analysis, time-frequency) | — |
| 4 | Human physiology (cardiovascular, respiratory, autonomic, biomechanics, sleep) | — |
| 5 | Wearable hardware & embedded systems (MCUs, power, BLE, RTOS) | — |
| 6 | Time-series machine learning | — |
| 7 | Human Activity Recognition (HAR) | ✅ Written (Competency 9) — gate open |
| 8 | Sensor fusion (Kalman family, complementary/Madgwick/Mahony, Bayesian) | — |
| 9 | Personalized anomaly detection | ✅ Written (Competency 11) — gate open |
| 10 | Digital biomarkers & digital phenotyping | ✅ Written (Competency 14) — gate open |
| 11 | Emergency detection systems (fall, crash, cardiac, seizure) | — |
| 12 | Context awareness & behavioral modeling | — |
| 13 | Privacy & security (on-device AI, federated learning, DP, TEE) | ✅ Written (Competency 13) — gate open |
| 14 | Edge AI / TinyML | — |
| 15 | Mobile & backend architecture (iOS, Android, Wear OS, scalable alerting) | — |
| 16 | Medical AI, clinical validation & regulatory (FDA, sensitivity/specificity, alarm fatigue) | ✅ Written (Competency 15 — FINALE) — gate open |

## Module 1 — Sensor Fundamentals: chapter list

| Ch | Topic | Status |
|----|-------|--------|
| 1.1 | **Accelerometer (MEMS)** | ✅ PASSED (Week 1 test, 2026-07-13) |
| 1.2 | Gyroscope | ✅ PASSED (Competency 2, 2026-07-13) |
| 1.3–1.4 | Magnetometer + IMU, 6/9-axis, calibration (combined chapter) | ✅ PASSED (Competency 3, 2026-07-13) |
| 1.5 | Sensor fusion (intro; deep dive in Module 8 → Competency 10) | ✅ Written (Competency 10) — gate open |
| 1.6 | GPS/GNSS (GLONASS, Galileo, BeiDou, A-GPS) | ✅ PASSED (Competency 6, 2026-07-13) |
| 1.7 | Wi-Fi / Bluetooth / UWB positioning, dead reckoning, geofencing, indoor positioning | ✅ Written (Competency 7) — gate open |
| 1.8 | PPG (photoplethysmography) | ✅ PASSED (Competency 4, 2026-07-13) |
| 1.9 | ECG | — |
| 1.10 | Heart rate & HRV | ✅ PASSED (Competency 5, 2026-07-13) |
| 1.11 | SpO₂ | — |
| 1.12 | Respiratory rate | — |
| 1.13 | Skin/body temperature | — |
| 1.14 | EDA/GSR | — |
| 1.15 | Blood-pressure estimation (PTT/PAT) | — |
| 1.16 | Barometer & altimeter | — |
| 1.17 | Ambient light, UV, humidity, air quality (CO₂, VOC) | — |
| 1.18 | Proximity: IR, capacitive, ToF, LiDAR | — |
| 1.19 | MEMS microphones, beamforming, wake word, noise suppression, audio fingerprinting | — |
| 1.20 | Cameras: RGB, depth, IR, thermal, event cameras | — |

**Current position:** Competency 15 (FINALE) — Medical AI/Clinical Validation/Regulatory + B14 (Medical-Device Software Engineering) written; **gate open — this is the LAST gate of the core arc.** Competencies 1–14 PASSED (through 2026-07-13). Chapter template §1–22. Master graph: [03-KNOWLEDGE-GRAPH.md](03-KNOWLEDGE-GRAPH.md). Doctrine 21 decisions. **RAXHA Canon built** ([05-RAXHA-CANON.md](05-RAXHA-CANON.md), AQ-5 ratified). AQ-6 (Institute of Leadership) queued. Mission: RAXHA = Human State Intelligence System. **On passing Competency 15: the CORE ARC (1–15) is COMPLETE** — the buildable/defensible RAXHA spine — and the Academy opens the founder-scale phase (Institutes C Human Behavior & Society, D Intelligence Research incl. deep company reverse-engineering, E Clinical & Safety Sciences; then Institute of Leadership). Ratified amendments: AQ-1 (Historian §21.6), AQ-2 (standing "most likely failure" gate question). Doctrine Decisions #11–14: (#11) no single device sole source of truth; (#12) three truths scientific/platform/product; (#13) absence of evidence ≠ evidence of absence + asymmetric default (low confidence + alarming context → ask, never silence); (#14) non-wear is the top field failure and it's a product problem. Amendment queue currently EMPTY.
