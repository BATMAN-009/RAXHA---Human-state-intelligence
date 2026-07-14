# The RAXHA Canon

> **The enduring laws of RAXHA, distilled.** Every doctrine decision that permanently shaped the architecture, reduced to one canonical line. A new engineer, clinician, or product lead should internalize RAXHA's philosophy in an hour — the way Amazon's Leadership Principles or Toyota's production principles compress a culture. Full reasoning for each lives in [01-ENGINEERING-DOCTRINE.md](01-ENGINEERING-DOCTRINE.md); this is the memorizable core.
>
> **Single canonical index (2026-07-14):** the Canon uses the **Doctrine IDs D01–D22** — the *only* numbering in the project. Every chapter, ADR, PDR, Blueprint, and test cites `D17` or `D22` and means exactly one thing. The Canon no longer numbers itself independently.
>
> **The Mission (the one sentence above all laws):** RAXHA is a **Human State Intelligence System that detects meaningful changes in a person's physiological, behavioral, and contextual state and helps the right people respond at the right time. It does not diagnose diseases or provide treatment.** It exists to answer *"What is the current state of this human, how confident are we, and does someone need to know?"* — a system for **allocating human attention under uncertainty**, where the Decision Engine is where **engineering becomes accountability**. It does not replace doctors, responders, or caregivers; it ensures they are informed sooner.

---

## The Prime Constraint
**1 second can be the difference between life and death.** Optimize for reliability — not convenience, development speed, or cross-platform reach.

## The Laws (by Doctrine ID)

**D01 — Native safety layer.** No cross-platform framework touches the life-critical path.

**D02 — On-device risk engine.** The SOS decision is made locally; the cloud coordinates, it never *gates*.

**D03 — No LLM in the detection path.** Detection = deterministic logic + validated ML. LLMs only explain, summarize, assist.

**D04 — Tier autonomy.** Every tier (sensor → watch → phone → cloud) must do something useful when everything above it is unreachable.

**D05 — Data plane.** Raw waveforms die on the watch; features cross to the phone; events cross to the cloud (battery, privacy, bandwidth — one rule).

**D06 — Delivery contract.** At-least-once + idempotent at every hop; an alert isn't "sent" until a human acknowledged it; unacknowledged alerts climb the ladder.

**D07 — Latency is budgeted, not hoped for.** Every pipeline stage has a measured target and a regression test.

**D08 — Shadow mode before live.** No detector alerts real users until it has run silently on fleet data and its real-world false-positive rate is known.

**D09 — Coverage telemetry is the first KPI.** Continuously measure the % of each day the user was actually protected; never hide a gap.

**D10 — Architecture before code.** Design docs, threat model, FMEA, latency + battery budgets, test plan — before production implementation.

**D11 — No single device is ever the sole source of truth for life-critical state.** Distributed: boot-readable journal + cloud dead-man's switch + watch autonomy.

**D12 — Three kinds of truth, never confused.** Scientific (cite evidence) / Platform (re-verify each OS release) / Product (revisable — not laws of nature).

**D13 — Absence of evidence is never evidence of absence.** Track measurement-confidence separately from state-confidence; low confidence + alarming context → *ask* ("are you OK?"), never silence.

**D14 — Non-wear is the top field failure, and it is a product problem.** No algorithm recovers physiology never measured; monitor contact-confidence and coach *before* the emergency.

**D15 — Every output speaks the responder's vocabulary, not the sensor's.** "Possible fall," not "2.8 g." Communicate what the system *can't* know, too — admitted uncertainty earns more trust than fabricated precision.

**D16 — Classify *changes* in people, not people.** Personal-baseline deviation is the signal; population models initialize, personal models govern.

**D17 — Hierarchy of responsibility: no lower layer makes a higher layer's decision.** Only Risk and Policy convert evidence into action.
> *Corollary:* Context may raise or lower confidence, but may **never independently suppress** a life-critical event (the veto contract).

**D18 — Confidence must be *calibrated*, not merely reported.** Fusion combines *calibrated beliefs*; uncalibrated confidence is worse than none.
> *Corollary:* A **contradiction between two trustworthy sensors is information, not noise** — it names a state neither sensor alone could (running + at-home = treadmill).

**D19 — Optimize appropriate interruption, not detection accuracy.** Every alert spends a finite trust budget; a system that just cried wolf should get *more* conservative. Maximize *true help delivered per unit of trust spent.*

**D20 — Missed emergencies are invisible.** False alarms are loud; misses leave no telemetry. Govern thresholds like models; *manufacture* the missing signal (drills, shadow mode, two-sided false-alarm + estimated-miss metrics).

**D21 — Privacy is trust-minimization: eliminate single points of trust like single points of failure.** On-device, federated, secure-aggregation, DP, E2E, minimization — each removes a trust dependency, including trust in the company itself. **Never monetize location or sensor data.**
> *Corollary:* **Every claim carries its evidence** — Confidence Ledger (★1–5), TRL, V3 validation; ✅ documented / 🟡 inferred / 🔴 unknown. Never ★★ evidence with ★★★★★ marketing.

**D22 — The Boundary — RAXHA is not a physician.** It detects, monitors, assesses risk, notifies, shares context, and encourages professional evaluation. It does **not** diagnose, treat, prescribe, advise medically, decide clinical management, or claim to cure/prevent/treat disease.
> *Corollary:* **Measurement is not meaning** — sensors measure reality, algorithms estimate hidden states, biomarkers summarize trajectories; *medicine* decides what they mean. Screening ≠ diagnosis.

---

*The Canon is v1.0-complete: all 22 doctrine decisions represented, IDs = Doctrine IDs (D01–D22), the four supporting principles held as corollaries under D17/D18/D21/D22. It grows only when the Doctrine does. Adding a law is a deliberate act; each must earn its place.*
