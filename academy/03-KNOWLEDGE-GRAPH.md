# RAXHA Knowledge Graph — The Graph of Intelligence

> **Ratified from AQ-3, 2026-07-13.** This is the assembled dependency graph the curriculum builds toward: not isolated chapters, but a connected structure where each concept declares what it depends on, what depends on it, which RAXHA subsystem and AI models consume it, which sensors feed it, which assumptions keep it valid, and how confident we are. Each chapter's §22 contributes its node here.
>
> **Mission anchor:** every node is a piece of the answer to *"What is the current state of this human, how confident are we, and does someone need to know?"* State-nodes build the estimate; every edge carries **uncertainty**, because (Competency-6 principle) every sensor produces an estimate, not a fact.

---

## The intelligence flow (macro-graph)

```
      Accelerometer ──┐
        Gyroscope ────┤
      Magnetometer ───┼──▶ IMU / Motion Context ──┐
     (IMU calibration)┘                            │
                                                   ├──▶ Human Gait ──▶ HAR ──┐
              PPG ──▶ HR ──▶ HRV ──▶ Personal      │   (Comp 8)   (Comp 9)   │
                              Baseline ────────────┤                          │
                                                   │                          ▼
        GPS/GNSS ──┐                               │                   Sensor Fusion (Comp 10)
   Wi-Fi/BLE/UWB ──┼──▶ Location Intelligence ─────┘                          │
      Geofencing ──┘    + semantic place                                      ▼
                                                                    Digital Biomarkers
                                                                              │
                                                                              ▼
                                                                     Anomaly Detection
                                                                              │
                                                                              ▼
                                                                       Context Engine
                                                                              │
                                                                              ▼
                                                                        Risk Scoring
                                                                              │
                                                                              ▼
                                                                    Emergency Decision (SOS)
                                                                              │
                                                                              ▼
                                                             Escalation / Response  ← the moat
```

Every arrow is an **uncertainty-propagating edge**: an estimate + its confidence flows forward; fusion is the arithmetic of combining them.

---

## Node registry (Competencies 1–6)

Legend — **Subsystem:** which RAXHA layer uses it. **Models:** AI that consumes it. **Assumptions:** what must hold or the node is invalid (→ Decision #13, mark "unknown," don't trust). **Conf:** current confidence (★1–5, from each chapter's §21).

| Node (concept) | Depends on | Depended on by | RAXHA subsystem | AI models | Sensors | Assumptions that must hold | Conf |
|---|---|---|---|---|---|---|---|
| **Proper acceleration / impact** (C1) | — | fall trigger, crash, HAR, fusion | Tier-0 trigger | threshold; TinyML confirmer | accel | not clipped (±16g wrist); on-body; calibrated bias | ★★★★★ |
| **Free-fall signature** (C1) | proper accel | fall detection | Tier-0/1 | threshold + classifier | accel | fall has ballistic phase (fails for soft/syncope falls) | ★★★★ |
| **Orientation / rotation** (C2) | accel (gravity ref) | posture, fall confirm, fusion | Tier-1 confirmer | fall classifier | gyro+accel | integrate only over seconds (drift); gyro powered in time | ★★★★ |
| **Absolute heading / yaw** (C3–4) | gyro, accel, mag | wandering, context | Tier-2 context | — | mag+IMU | field plausible (magnitude+dip); indoors unreliable | ★★★ |
| **IMU calibration** (C3–4) | accel, gyro, mag | ALL motion features | acquisition | — | all IMU | rest-period recalibration; temp-indexed; band-swap detected | ★★★★★ |
| **Pulse / heart rate** (C4) | — | HRV, cardiac trigger, fusion | Tier-2 confirm + slow trigger | HR estimator (accel-fused) | PPG(+accel) | good SQI; motion-referenced; not signal-loss-as-no-pulse | ★★★★★ |
| **Signal-loss ≠ no-pulse** (C4) | pulse, SQI | cardiac safety | risk engine guard | — | PPG+accel+contact | corroborate before any no-pulse escalation | ★★★★ |
| **HRV / PRV** (C5) | pulse, IBI cleaning | personal baseline, illness, context | baseline engine | anomaly (Module 9) | PPG(/ECG) | still window; SQI-gated; artifact-corrected; metric+condition tagged | ★★★★ (rest) |
| **Personal baseline** (C5) | HR, HRV | anomaly detection, risk scoring | baseline engine | Gaussian→CPD→autoencoder | PPG+context | enough history (cold-start = wide priors); per-user | ★★★★★ (method) |
| **Position / location** (C6) | — | context, alert payload, geofence | Tier-2 context + payload | map-match, KF | GNSS(+Wi-Fi/BLE) | accuracy is optimistic (multipath); check staleness; indoors unusable | ★★★★★ open-sky / ★★ urban |
| **Semantic place** (C6) | location, geofence | context gating, escalation policy | Context Engine | — | GNSS+geofence | radius≥accuracy; dwell+hysteresis; corroborate | ★★★★ |
| **Speed / driving context** (C6) | location (Doppler), accel | false-alarm gating, crash | Context Engine | — | GNSS Doppler+IMU | Doppler speed > position-derived; sustained vs transient | ★★★★ |

---

## Cross-cutting invariants (edges that touch every node)

- **Uncertainty propagation (mission "confidence" clause / Decision #13):** every node emits (estimate, confidence, timestamp). "Unknown" is a first-class value, never silently read as "normal."
- **Gated-absolute-reference pattern:** magnetometer (C3–4), GPS accuracy (C6), PPG-under-motion (C4/C5) all follow *drifting-but-smooth spine + absolute-but-lying reference admitted only under plausibility checks.* One pattern, reused at every layer.
- **The cascade / power gating:** cheap always-on sensor (accel, µA) gates expensive ones (gyro mA, PPG mW, GPS mW). Power flows opposite to the intelligence graph.
- **Distributed truth (Decision #11):** no node's on-device value is the sole authority; cloud mirror + dead-man's switch backstop every state.
- **Non-wear (Decision #14):** the graph produces nothing if the device isn't worn/contacting — contact-confidence is the graph's root health metric.

---

## How AI models map onto the graph (forward reference)

| Model class | Consumes nodes | Produces | Chapter home |
|---|---|---|---|
| Threshold / interrupt engine | impact, free-fall | Tier-0 trigger | C1, on-sensor |
| TinyML window classifier | accel+gyro features | fall confirm | C9 HAR / B8 TinyML |
| HR estimator (accel-fused) | PPG+accel | heart rate + SQI | C4 |
| Personal-baseline / anomaly | HR, HRV, gait, mobility | deviation score | Module 9 |
| Sensor fusion (KF/EKF/DL) | all state nodes + uncertainties | single high-conf state | C10 (seed saved) |
| Context / risk scoring | fused state + semantic place | risk score | Context/Decision engine |
| LLM (bounded, NON-detection) | events, history | explanation/summary for caregiver | never in detection path (Doctrine #3) |

*Graph grows with each competency. Gait (C8) inserts between Motion Context and HAR; Fusion (C10) is where all edges converge.*
