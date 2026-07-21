# VVE-001 — Digital Validation Laboratory (founder directive, 2026-07-21; laboratory framing v2)

> **Not a simulator. A laboratory.** Every experiment behaves exactly like owning watches, *except where reality cannot honestly be simulated*. The laboratory exists to answer one question: **"If the watches arrived today, what uncertainty would still remain?"** — and the answer must be: *only hardware uncertainty. Nothing else.* We replace physics, never truth.
> **Founder success metric:** when SPIKE-002 begins, we are not building RAXHA — we are cross-examining it. The watches are witnesses; the laboratory is the courtroom; evidence decides.
> **Evidence taxonomy (binding, machine-labeled on every artifact):** `SIMULATED` · `REPLAY-DERIVED` · `HARDWARE-VALIDATED`. The corpus `provenance` block carries it; the gate REJECTS unlabeled input. Simulator/hardware divergence becomes a new evidence artifact — never a silent patch.

## Accepted architecture corrections (founder-ratified)

Mock at the **frozen port boundary**, not HealthKit APIs (Apple adapter exists only when Mac + hardware exist — swap step) · Health Connect **deferred** (no Android tier in frozen v1) · web-based lab console (platform reality) · **VV-111 adapter-swap invariance** as CI gate · simulators never manufacture evidence for pre-registered P1–P7 (hardware-only).

## What the laboratory validates / isolates as hardware-only

**Validates (desk, CI-enforced):** FSM + write-ahead + recovery, incident pipeline, policy/risk decision spine, confidence propagation, replay determinism, ladder/dead-man timing logic, guardian routing, evidence collection, timeline reconstruction, audit viewing.
**Hardware-only (isolated, pre-registered):** sensor physics/noise, battery, watchOS scheduling, HealthKit latency, BLE/LTE, hardware reliability = predictions P1–P7. The lab must never contain a mock whose behavior would resolve them.

## Laboratory model

### 1. Case files, not scenarios
Every experiment is a **numbered case file** (`cases/CASE-0001-kitchen-fall.json` + report), containing: subject profile · scenario · **ground truth** (what actually happened) · **expected outcome** (what SHOULD happen, derived from SRS/hazard controls, never invented per-case) · expected evidence chain · **pinned behavior** (regression hash of what the current verified system DOES) · provenance label · regression-protected flag.
**Two expectations, never blurred:** ground-truth assertion vs pinned regression. Legal statuses: `PASS` (matches both) · `KNOWN-DEFICIENT` (matches pin, fails ground truth — visible, tracked, linked to its fix item) · `REGRESSION` (diverged from pin) · `BLOCKED`. A case may never be made green by editing its expectation — expectation changes are reviewed like code (claims-under-configuration-control, gate-record artifact 9).
**Growth rule:** every production bug, every hardware divergence, every field incident becomes a permanent case. The predecessor's incidents already seeded cases 001–006 (the existing corpus). Target: hundreds.

### 2. Guardian World
People are simulated, not just watches. Guardian behavior profiles behind the delivery ports: *always-responds · busy-parent · night-shift · elder-spouse · poor-network · muted · delayed-ack · never-acks · wrong-contact · travelling*. Each profile × each escalation scenario = a case exercising ladder timing, retries, reminders, dead-man, exactly-once-effect. The question every run answers: **does the ladder still behave correctly when humans don't?**

### 3. TimeController (already load-bearing, now exercised)
The core is *already* wall-clock-free (VV-101 determinism; deadlines are persisted data, not timers — Blueprint A6). The lab adds the controller: compress 24 h → 30 s, dilate 2 min → real-time, step, pause, jump (incl. clock-drift and reboot-epoch cases feeding RFC-008). Every timeout/retry/reminder/dead-man fires under injected time. Any code found depending on wall-clock = architecture violation, filed as a finding.

### 4. FaultKit
Deliberate failure injection, every fault a permanent regression case: battery-death mid-COUNTDOWN · BLE loss · watch reboot · GPS unavailable · permission revoked · HR delayed · accelerometer freeze · duplicate samples · out-of-order samples · clock drift · corrupted payload · replay interruption. (Reboot/clock cases double as RFC-008 test beds.)

### 5. DiffEngine — the three-leg protocol
`Replay ⇄ Simulation ⇄ Live Hardware → Diff Report`. Report format: Expected → Observed → decision difference → confidence difference → latency difference → **attribution**: `INPUT-DELTA` (sensor/timing reality — expected on hardware; becomes evidence, feeds P1–P7 scoring) vs `LOGIC-DELTA` (same inputs, different decision — **architecture failure, zero tolerance**).
**Sharpened success metric:** decisions on identical inputs = **100% identical** (VV-111); input/timing deltas are not failures — they are the hardware findings the lab exists to isolate. "95% identical" as a blended number is banned: it would average a catastrophe into a pass.

### 6. Automatic evidence packages
Every run auto-generates: case ID · inputs · ground truth · decision · confidence · timeline · evidence used · **evidence missing** · latency · status · regression hash · provenance label. No manual documentation. The existing hash-verified decision log is the substrate; the package is its structured rendering.

### 7. Audit viewer + lab console
Web console driving the harness: `simulate*()` buttons and sliders (battery/HR/HRV/motion/GPS/connectivity/charging/worn/permissions/Family-Setup/contacts) → case run → full pipeline visible: sensor stream → FSM transitions → confidence → guardian timeline → ladder → dead-man → ack → replay archive → evidence package → decision log. Every view stamped with its provenance label.

## Hardware Arrival Day protocol

One action: **Run All (simulation) → Run All (Apple Watch) → Diff Report.** Zero LOGIC-DELTA = the architecture succeeded. Every INPUT-DELTA = a numbered finding scored against the pre-registered predictions. Development does not restart on arrival day; cross-examination begins.

## Build increments (each = own PR, CI-gated)

1. **I1 — CaseKit + case schema + scenario library** (normal-day, workout, stress, fall, soft-fall, unconscious, night-charging, unknown — as case files w/ `SIMULATED` provenance; corpus-gated, deliberate rebaseline).
2. **I2 — Injection API + FaultKit** (`simulate*()`, 12 fault classes, expected-transition assertions as tests).
3. **I3 — Streaming virtual adapters + TimeController + VV-111** invariance rig.
4. **I4 — Guardian World + notification simulator** (profiles × ladder; exactly-once; dead-man).
5. **I5 — Lab console + audit viewer + auto evidence packages.**
6. **I6 — DiffEngine three-leg + Hardware Swap** (macOS stage: Apple adapters conform to ports; arrival-day protocol executed; divergences → findings).

## Success criteria (honest form)

- Every core/pipeline behavior exercised by ≥1 case; coverage **measured and reported**, never asserted.
- VV-111 green: adapter swap ⇒ byte-identical decision logs on identical inputs.
- KNOWN-DEFICIENT visible on the dashboard — the lab surfaces deficiencies; it never launders them.
- Every simulated artifact labeled `SIMULATED — NOT HARDWARE EVIDENCE`; unlabeled input is REJECTED.
- P1–P7 remain unresolved by the lab; on arrival day they are resolved by witnesses only.
