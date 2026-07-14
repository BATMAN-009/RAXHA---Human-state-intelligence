# PLANNED COMPETENCY — Human Gait Intelligence

> **Status:** SPEC LOCKED (user-directed, 2026-07-13). **Write when reached** — positioned as a *standalone competency* immediately **after** the Location competencies (GPS/GNSS + Wi-Fi/BT/UWB/indoor positioning) and **before** HAR. Gait is treated as one of RAXHA's core *intelligence layers*, the bridge from physiology to Human Activity Recognition — NOT as a single sensor or a mere activity class.
>
> Follows the full chapter template §1–21 (incl. Founder Intelligence, Design Review, Constraint Exercise, Chief Scientist's Verdict with all six subsections). Integrates every sensor already learned: accelerometer, gyroscope, magnetometer, PPG, HR/HRV, barometer, GPS, and the sensor-fusion concepts from Module 8.

## Multidisciplinary framing
Built on biomechanics + physiology + sensor fusion + behavioral intelligence. The chapter is organized into **three domains, taught separately**, each ending with RAXHA-specific application (fall prediction, anomaly detection, context-aware safety, geofencing, child protection, senior care, personalized baselines).

### Domain 1 — Clinical Gait Analysis *(taught as the clinical context RAXHA operates in — Decision #22; RAXHA monitors and estimates risk, it does not diagnose these conditions)*
Gait cycle (stance/swing phases, heel-strike to toe-off); cadence; stride length; stride width; **gait speed ("the sixth vital sign")**; symmetry; double-support time; stride-to-stride variability; balance; frailty; and the gait signatures associated with Parkinson's disease, stroke, dementia, and musculoskeletal disorders (understanding these lets RAXHA *recognize meaningful deviation and encourage professional evaluation* — not diagnose). Culminates in **fall-risk estimation / early awareness** (variability + speed decline as the strongest known pre-fall indicators) and rehabilitation *progress monitoring* — all as observation feeding evidence-based escalation, never clinical management.

### Domain 2 — Behavioral Gait Intelligence
Gait as a **digital biomarker**; longitudinal mobility monitoring; personal behavioral baselines; anomaly detection on gait; mobility decline; fatigue detection; stress effects on gait; wandering detection (dementia elopement); child behavior; senior monitoring; recovery tracking. This domain is where gait feeds RAXHA's personalized-baseline engine (built in Ch 1.10) and the anomaly-detection module (Module 9).

### Domain 3 — Gait Recognition & Privacy
Gait as a **behavioral biometric**; identity recognition; **device-user verification / wearer-identity confidence** (ties to Doctrine Decision #14, non-wear/wrong-wearer); continuous authentication; sensor fingerprinting; privacy implications; adversarial attacks and spoofing; ethical considerations; defensive techniques. Cross-references Ch 1.1 §11 (gait as accelerometer fingerprint) and Module 13 (privacy).

## Cross-references already seeded in passed chapters
- Ch 1.1 §11 — gait as a biometric revealed by continuous accelerometry (privacy threat).
- Ch 1.2 §12, §18 — gyro-derived gait metrics as validated biomarkers for Parkinson's/tremor/**fall-risk**; gait-quality startup opportunity.
- Ch 1.10 — personal-baseline-deviation philosophy that gait analysis will extend to mobility.
