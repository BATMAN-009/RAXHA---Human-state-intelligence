# SPIKE-002 Execution Plan — Borrowed-Lab Protocol

> **Context (2026-07-21):** a complete Apple lab is available via a collaborator — Mac + iPhone + Apple Watch Ultra. This plan adapts the [SPIKE-002 protocol](SPIKE-PLAN-002-010.md) and the [locked pre-registration](SPIKE-002-PREREGISTERED-PREDICTIONS.md) to that reality. The pre-registration is NOT edited (lock holds); results resolve against it with device-class noted.

## Workflow & responsibilities

```
Founder PC (Windows) → GitHub (PRs) → Collaborator's Mac → Xcode → iPhone → Watch Ultra → logs/results → GitHub
```

- **Founder (Windows):** architecture, RFCs, state machine, algorithms, experiment definitions, reviews every PR.
- **Collaborator (Mac):** pull, build in Xcode, deploy to simulator/device, execute experiment scripts, capture logs, push results. Needs repo collaborator access.
- **Claude:** generates Swift/watchOS code, fixes build errors, writes adapters, interprets logs, produces patches — on either machine via Claude Code.

## Evidence rules (binding, from the frozen doctrine + advisor)

1. Every result is labeled exactly one of: **`simulated`** (desk/replay), **`simulator`** (Xcode watch simulator), **`hardware`** (physical device). Only `hardware` resolves pre-registered predictions.
2. **Never invent hardware results.** If a step needs a physical watch, produce the experiment + expected observations, and wait for the device run. A missing result is reported NOT-EXERCISED — never inferred.
3. Every PR states what was validated, at which evidence level, on which device class (**Ultra ≠ Series-4 floor** — Ultra results are flagged `device-class: Ultra`, battery results especially).
4. Logs land in the repo (spike-evidence directory) with timestamps; interpretations reference raw logs, not memories of them.

## Prerequisites (file/start BEFORE Day 1)

- [ ] **A1 filed on the company's paid Apple Developer account** — fall-detection entitlement (~2–3 days) + critical-alerts request. The entitlement attaches to OUR app ID/team; do not build spike evidence on a personal team that can't carry it. **This gates Day 5.**
- [ ] Collaborator added to the GitHub repo; Xcode signed into the company team.
- [ ] For the **managed-watch phase (Day 6): a second Apple Account + watch cellular plan (eSIM)** — Family Setup requires the watch to be wiped, re-provisioned as a family member's device with its own number. Collaborator's informed consent required (their device is wiped and restored after).

## Day plan (maps to pre-registered predictions)

| Day | Work | Predictions exercised | Evidence level |
|---|---|---|---|
| 1 | Minimal watchOS app; deploy to Ultra; watch↔iPhone↔backend round-trip | pipeline sanity | hardware |
| 2 | Read accelerometer/gyro (CMBatchedSensorManager — Ultra qualifies, Series 8+); heart rate where available; timestamped logging | **P5** (sensor quality vs corpus assumptions), **P6** (HealthKit reads) | hardware |
| 3 | Motion sessions: walk/run/sit/lie; controlled safe-fall surrogates onto padding (NO risk to persons — these test OUR logging, not Apple's detector) | **P5** corpus traces (first own recordings — SPIKE-010 seed) | hardware |
| 4 | Background execution matrix (foreground/background/terminated/Low Power); notifications; connectivity drops; battery log over the day | **P2**, **P3**, **P4** (flag: Ultra battery ≫ floor), **P7** (forced-reboot recovery run) | hardware |
| 5 | *(entitlement granted)* Fall-API test, **paired mode**: simulated fall → native UI → `didDetect` + resolution delivery timing | P1 paired-baseline (not the decider) | hardware |
| 6 | **Family Setup reconfiguration**: wipe, re-provision as managed watch, reinstall app from watch App Store, repeat Day-5 fall-API test + LTE upload with iPhone absent | **P1 — THE decider** (RFC-005), **P3** true no-phone leg | hardware |
| 7 | Restore collaborator's watch; write results report scoring every pre-registered row (CONFIRMED/FALSIFIED/PARTIAL/NOT-EXERCISED + both priors' Brier) | calibration measurement | — |

**Sequencing logic:** Days 1–4 need no entitlement and no reconfiguration — they run immediately while A1 clears. Day 6 is the only day that answers the question the spike is named for; everything before it de-risks that day. If Day 6 cannot happen (consent/eSIM/logistics), the spike still resolves P2–P7 and **P1 is reported NOT-EXERCISED — not assumed** — and RFC-005 stays conditional.

**Out of scope, explicitly:** production algorithms (post-spike, per advisor), old-hardware floor (needs Series-4-class device later), SPIKE-007/008 (need A2/critical-alerts).
