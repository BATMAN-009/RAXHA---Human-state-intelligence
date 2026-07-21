# VVE-001 — Virtual Validation Environment (founder directive, 2026-07-21)

> **Objective:** before physical watches arrive, the software behaves like a production system fed by simulated inputs; hardware later replaces *only* the device adapters. Any downstream code change at swap time = architecture failure.
> **Evidence taxonomy (binding, on every artifact):** `SIMULATED` · `REPLAY-DERIVED` · `HARDWARE-VALIDATED`. The corpus `provenance` block (built for AUDIT-003's traces) already carries this; VVE extends it to every scenario, report, and dashboard view. **No artifact may blur the boundary.** Divergence between simulator and hardware becomes a new evidence artifact (per the SPIKE-002 pre-registration principle) — never a silent patch.

## What VVE-001 validates / cannot validate

**Validates (desk, CI-enforced):** state machine (FSM + write-ahead + recovery), incident pipeline, policy/risk decision spine, confidence propagation, replay determinism, guardian notification *routing logic*, escalation ladder timing logic, evidence collection, timeline reconstruction.
**Cannot validate (hardware-only, isolated by design):** sensor accuracy/noise, battery, watchOS scheduling/background windows, real HealthKit latency, BLE/LTE behavior, hardware reliability. These are exactly pre-registered predictions P1–P7 — the VVE must never manufacture evidence for them.

## Deliverable map — existing vs new

| # | Directive deliverable | Already exists (Phase 0) | Gap VVE-001 builds |
|---|---|---|---|
| 1 | Virtual Watch Adapter | 8 frozen ports + IdSource; replay harness feeds traces through them | **Streaming-mode virtual adapters** (live feed, not just batch replay): accel/gyro/HR/HRV/battery/connectivity/worn-state simulators behind the ports |
| 2 | HealthKit Simulator | Ports isolate core from HealthKit entirely | **Port-boundary mock** with full fault vocabulary: unavailable, permission-revoked, delayed/missing/duplicate samples. *True HK-signature mock deferred to macOS (Hardware Swap Plan step 1)* |
| 3 | Health Connect Simulator | — | **DEFERRED** — no Android tier in frozen v1 scope (RFC-005/PDR); revisit at the Android RFC, not before |
| 4 | Vital Generator | 4 synthetic + 2 real traces | **ScenarioKit**: deterministic generators (seeded, replay-stable) for the scenario library below |
| 5 | Incident/Fall Injection | trace-005 (real cancelled fall) | `simulate*()` API: fall, soft-fall, trip, watch-drop, bed-collapse, running-stop, wheelchair-transfer, false/true-positive, unknown — each = a scenario constructor emitting frozen-schema events with expected-transition assertions |
| 6 | Replay Dataset | 6-trace corpus + golden hashes + BLOCKED-on-vacuous gate | Scenario library lands as corpus expansion (`SIMULATED` provenance), gated by the same rigs + deliberate rebaseline discipline |
| 7 | Scenario Library | — | Normal-day · workout · stress (HR↑/HRV↓) · fall→stillness→recovery · unconscious (spike→stillness→HR-decline) · night-charging/non-wear · unknown (timeout/battery/permission) |
| 8 | Watch Debug Dashboard | — | **Web-based console** (platform reality: SwiftUI won't run on this desk): sliders (battery/HR/HRV/motion/GPS/connectivity/charging/worn/permissions) → scenario JSON → harness run → rendered output |
| 9 | State Timeline Viewer | Decision log (hash-verified) | Timeline renderer over the decision log — every transition, deadline, veto-check, confidence value, with provenance labels |
| 10 | Guardian Simulator | Ladder/contracts specified (IF-HUM-01…05) | Guardian-behavior model behind delivery ports: ack/ignore/delay/mute profiles → exercises ladder timing + dead-man logic |
| 11 | Notification Simulator | Delivery ports defined | Deterministic delivery simulator incl. failure modes (undelivered, delayed, duplicate) → exactly-once-effect tests |
| 12 | Hardware Swap Plan | Port architecture is the plan's skeleton | §Swap below |

## Architecture rule (the invariance gate)

Virtual adapters, replay feed, and (future) hardware adapters implement the **same ports**. New CI test — **VV-111 adapter-swap invariance**: identical scenario through virtual-streaming adapter vs batch replay ⇒ byte-identical decision log. When hardware arrives, the same scenario re-run on-device becomes the third leg; any divergence = evidence artifact + register row, not a patch.

## Build increments (each = own PR, gated by existing CI)

1. **I1 — ScenarioKit + scenario library**: deterministic generators → traces in frozen 08B schema, `SIMULATED` provenance, corpus-gated (expect NO_BASELINE → deliberate rebaseline).
2. **I2 — Injection API** (`simulate*()`) + expected-transition assertions as XCTests.
3. **I3 — Streaming virtual adapters** (sensors, battery, connectivity, worn) + VV-111 invariance rig.
4. **I4 — Guardian + notification simulators** → ladder/dead-man/exactly-once tests.
5. **I5 — Web debug dashboard + timeline viewer** (drives the harness binary; renders decision logs; every view stamped with provenance).
6. **I6 — Hardware Swap Plan execution** (macOS/Xcode stage): Apple adapters conforming HealthKit/CoreMotion/CMFallDetection to the ports; VVE scenarios re-run on-device; divergences → new SPIKE artifacts.

## Success criteria (honest form)

- Every core + pipeline behavior exercised by ≥1 scenario; coverage **measured and reported**, not asserted (the "90%" is a target the coverage report either shows or doesn't).
- VV-111 green: adapter swap changes zero downstream behavior.
- Every simulated artifact machine-labeled `SIMULATED — NOT HARDWARE EVIDENCE`; the gate REJECTS unlabeled scenario input (extends the AUDIT-002 falsifiability repair).
- P1–P7 pre-registered predictions remain hardware-only: the VVE contains **no** mock whose behavior would resolve them.
