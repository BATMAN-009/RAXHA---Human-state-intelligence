# Chapter B12 — Testing, Release Engineering & Fleet Observability

> **Paired with:** Competency 13 (Privacy-Preserving AI). This chapter answers the hardest question the whole curriculum has raised — the one your Competency-12 answer exposed: **how do you test a system for the emergencies it must never miss, when you can't wait for real ones, and when the failure that matters most (a missed emergency) leaves no telemetry?** (Doctrine #20.) Testing a safety-critical, ML-driven, distributed, battery-constrained system is its own discipline, and it's where the difference between "demo" and "trustworthy" is actually enforced. Taught under the Principal Architect contract.

---

## 1. Why testing this system is uniquely hard

RAXHA violates every assumption normal testing relies on:
- **The critical event is rare and unobtainable:** you can't wait for real falls/cardiac events; you can't ethically cause them.
- **The worst failure is invisible:** a missed emergency produces no error, no crash, no ticket (Doctrine #20).
- **It's distributed and asynchronous:** watch↔phone↔cloud, flaky links, process death, reboots (Competency 2/3, B7).
- **It's ML-driven:** models drift, quantization shifts behavior, personalization diverges (B8/B9).
- **It's battery- and background-constrained:** it works on your desk and dies at 3 a.m. under Doze (B2/B3).
- **You can't fully test in production** because production failures can cost lives.

So RAXHA needs a *layered* test strategy where each layer manufactures the confidence that real-world observation can't provide.

---

## 2. The test pyramid for RAXHA

**Layer 1 — Deterministic core tests (fast, exhaustive).** `RiskEngineCore` is pure (no OS — B2/B3), so unit-test the FSM, risk scoring, and policy exhaustively: every state transition, every threshold, the reboot-at-T+10s scenario (Competency 2), the veto contract (Decision #17 — assert context can *never* zero out a real event). Milliseconds, no device.

**Layer 2 — The replay harness (the backbone).** Recorded and synthetic sensor traces (falls, ADLs, crashes, edge cases, reboots-mid-incident, link-drops) → run through the *actual* pipeline (acquisition→fusion→HAR→anomaly→decision) → assert the outcome ("this trace must end in ALERTING within 90s"; "this ADL must NOT alert"). This is how you test the rare event *repeatably* without waiting for it. The corpus includes the precious real-world falls (FARSEEING-class) and grows via shadow mode. **Runs in CI on every change**, including on the quantized/converted models (B8/B9 — validate what ships, not the float model).

**Layer 3 — Chaos / fault injection.** Kill the watch↔phone link mid-COUNTDOWN; reboot the phone mid-incident; drop the network during escalation; exhaust the battery; corrupt a sensor stream; make the cloud unreachable. Assert graceful degradation and the tier-autonomy invariant (Decision #4) and dead-man's switch (Decision #11) fire correctly. *The happy path is trivial; RAXHA is judged on these.*

**Layer 4 — Device/field matrix.** Real devices across the fragmentation surface (B3: OEM battery killers, sensor variance, Wear OS heterogeneity; Apple Watch envelope, B9). Background/Doze behavior on *release* builds, untethered (B2 — the debugger hides failures). Battery-budget regression tests (per-sensor duty cycle, B8/B9).

**Layer 5 — Shadow mode (the safest real-world test).** New models/thresholds run on real fleet data, logging *would-have-decided* without acting (B1). The only ethical way to measure real-world false-positive rate — and, with confirmed outcomes, a surrogate for false negatives — before enabling. This is how the SisFall→FARSEEING gap gets closed with *your* fleet.

**Layer 6 — Synthetic fleet drills (manufacturing the missing telemetry).** Injected synthetic incidents fleet-wide, daily (B10), that exercise the *entire* pipeline through delivery and acknowledgment — the safety equivalent of a fire drill. If the drill doesn't fire, the pipeline is broken and you know *today*, not during a real emergency. **This is the direct answer to Doctrine #20's invisible-failure problem: you manufacture emergencies you control to prove the system still responds.**

---

## 3. Release engineering — deploys that could cost lives

- **Everything safety-critical is a governed deploy:** app releases, **model updates (B8/B9), AND threshold/policy changes (Decision #20)** — all signed, versioned, canaried, shadow-tested, rollback-able. A threshold change is a clinical-behavior change and gets model-grade governance.
- **Staged rollout:** canary (small %) → monitor SLOs + coverage + FA/miss surrogates → progressive → full, with automatic rollback on regression.
- **CI/CD gates:** replay corpus must pass; battery regression must pass; the veto-contract test must pass; calibration (Decision #18) must not regress. Red on any → no ship.
- **Model/threshold registry:** every deployed artifact versioned, traceable, rollback-able, audit-logged (who changed what threshold, with what rationale — Doctrine #20).
- **Feature flags / kill switches:** disable a misbehaving detector fleet-wide instantly (a safety necessity, not a nicety).

---

## 4. Fleet observability — the fleet is the instrument (B1, matured)

- **Coverage telemetry (the first KPI, B1):** % of each day each user was actually protected (sensors sampling, pipeline alive, link up, on-body/worn — Decision #14). Segmented by device/OEM (B3). A coverage drop is a silent-non-protection alarm.
- **SLO dashboards (B10):** trigger→ack p99, delivery success per rung, acknowledgment rate, drill success.
- **The two-sided metric (Doctrine #20):** monitor FA/person-week *and* estimated-miss surrogates *together* — never optimize the visible one alone. Manufacture the miss signal via drills + shadow ground truth + user-reported misses.
- **Calibration monitoring (Decision #18):** is a "70% confident" decision right ~70% of the time in the field? Reliability diagrams on live outcomes; recalibrate on drift.
- **Model/personalization drift monitoring:** are federated/personalized models (C13) still performing? Drift → investigate.
- **Crash reporting + performance:** standard, but tied to the safety path (a crash in the risk engine is a coverage gap).
- **Privacy-preserving telemetry (C13):** observability itself must honor the data doctrine — aggregate/DP metrics, not raw streams; you instrument the fleet without surveilling it.

---

## 5. Failure modes (testing/release edition)

| Failure | Cause | Defense |
|---|---|---|
| Missed-emergency regression ships silently | Only false-alarm telemetry watched | Two-sided metrics + drills + shadow (Doctrine #20) |
| Model regression in production | Unshadowed/uncanaried deploy | Replay CI + shadow + canary + rollback (B8/B9) |
| Threshold quietly drifted unsafe | Ungoverned config change | Threshold = safety artifact; governed like a model (Doctrine #20) |
| Works in CI, dies on real device | Simulator/tethered testing only | Device matrix; release-build untethered background tests |
| Pipeline silently broken | No end-to-end synthetic test | Daily fleet drills through delivery+ack (B10) |
| Coverage gap unnoticed | No coverage telemetry | Coverage KPI segmented by OEM (B1/B3) |
| Calibration decayed | No field calibration monitoring | Reliability diagrams on live outcomes (Decision #18) |
| Observability leaks privacy | Raw telemetry streams | Aggregate/DP metrics (C13) |

## 6. RAXHA production shape

- **Replay corpus + harness** in CI (the backbone), growing from shadow mode + FARSEEING-class data; runs on quantized/converted models.
- **Chaos suite** (link/process/network/battery/sensor fault injection) in CI + staging.
- **Device farm / field matrix** across OEMs and watch models.
- **Shadow-mode infrastructure** (parallel decisioning, would-have-logged).
- **Daily synthetic-drill system** (fleet-wide end-to-end health check).
- **Governed release pipeline** for app + models + thresholds (signed, canaried, rollback, audit).
- **Observability stack:** coverage KPI, SLO dashboards, two-sided FA/miss metrics, calibration + drift monitors, privacy-preserving telemetry, kill switches.

## 7. Founder Intelligence

**Strategic reading:** the test/release/observability discipline *is* the reliability that is RAXHA's moat (B10) — it's unglamorous, has no demo value, and is exactly why safety incumbents are hard to displace and why a serious RAXHA is hard to displace once built. **The invisible-failure problem (Doctrine #20) is a genuine competitive frontier:** whoever best manufactures missed-emergency telemetry (drills, shadow, surrogates) has the safest product, and it's mostly *engineering discipline*, not IP — so it compounds with organizational maturity. **Why incumbents are strong here:** Apple/Google have deep release/observability muscle; RAXHA must match it as a small team by *automating* the discipline (replay CI, drills, governed deploys). **Ledger:** ✅ testing/release/observability practices (well-documented); 🟡 optimal miss-surrogate methods (emerging); 🔴 nothing hidden — this is discipline, not secrets. **Kill-relevant:** if the org can't sustain governed deploys + two-sided metrics + drills, it *will* drift toward invisible under-protection (Doctrine #20) — an operational-maturity kill risk more than a technical one.

## 8. Design Review (highlights)

- **SRE:** "Daily fleet drills through delivery+ack, chaos suite, governed rollouts with auto-rollback, kill switches. Show me you'd know the pipeline broke *today*, not at the next real emergency."
- **Chief Scientist:** "Replay CI on the *quantized* models; calibration monitored in the field; two-sided metrics. Prove a missed-emergency regression can't ship silently."
- **Regulator (Module 16):** "Threshold and model changes are clinical-behavior changes — versioned, rationale-documented, auditable, rollback-able. Show the change-control."
- **Privacy advocate:** "Your observability must not become surveillance — aggregate/DP telemetry, not raw streams (C13)."
- **Investor:** "This discipline is the reliability moat. It's why you're trusted and hard to copy. Show the drill success rate — that's the product's heartbeat."

## 9. Constraint Exercise

Design RAXHA's test + release + observability system to guarantee (as far as possible) that a missed-emergency regression cannot ship silently. Constraints: rare unobtainable critical events, invisible false-negative failures (Doctrine #20), a distributed flaky system, ML models that drift/quantize, OEM fragmentation, and privacy-preserving telemetry (C13). Specify: the replay corpus + CI gates, the chaos suite, shadow mode, the daily drills, the governed release pipeline for app/models/thresholds, the two-sided (FA + miss-surrogate) observability, and how you'd detect a silent under-protection drift within a week. One-page memo.

## 10. Chief Scientist's Verdict

**Confidence Ledger:** Replay-harness CI for rare-event testing — ★★★★★ (the backbone; standard + essential). Chaos/fault-injection for distributed safety — ★★★★★. Shadow mode for real-world FP rate — ★★★★★ (B1). Synthetic fleet drills manufacturing miss-telemetry — ★★★★☆ (the Doctrine-#20 answer; discipline to build). Two-sided FA+miss observability — ★★★★☆ (miss-surrogates are the hard part). Governed model+threshold deploys — ★★★★★.
**TRL:** Replay CI / chaos / shadow / drills / governed deploys — 8–9 (standard SRE+MLOps; RAXHA integration to build with rigor). Miss-surrogate observability — 6–7 (emerging discipline). Privacy-preserving telemetry — 7.
**Roadmap:** *MVP:* replay CI, deterministic core tests, veto-contract test, shadow mode, coverage telemetry, governed deploys, kill switches. *V2:* chaos suite, daily fleet drills, two-sided metrics, calibration/drift monitors. *V3:* automated miss-surrogate detection, full device farm. *Never Build:* production as the first test of the safety path; ungoverned threshold/model changes; one-sided (FA-only) optimization; observability that surveils.
**Competitor failures (sourced):** the broad "worked in demo, failed in the field" wearable pattern (reliability gaps — the reason for the device matrix + background testing). MLOps production regressions from unshadowed deploys (documented across industry — why replay CI + canary). Clinical-monitor alarm-load failures where one-sided optimization degraded safety (why two-sided metrics). Safety-system deploy failures across industries (why governed, rollback-able, audited releases).
**Kill Criteria:** if the org can't sustain governed deploys + drills + two-sided metrics, it will drift into invisible under-protection (Doctrine #20) — an operational-maturity failure; fix the discipline before scaling users. If replay/shadow can't validate a model on real-world (not lab) events, don't enable it. If drills can't run daily end-to-end, the pipeline's health is unknown — treat that as a Sev-1.
**Historical Failures (Historian):** the "demo-to-field" collapse (reliability, not features, killed many wearables). Production ML regressions from insufficient shadow/canary (industry-wide). Clinical alarm fatigue as a *testing/observability* failure (one-sided metrics optimized false-alarm reduction into missed events) — the empirical proof of Doctrine #20. Safety-critical OTA failures (why release governance is firmware-grade).

## 11. Knowledge Graph Connections

- **Depends on (prior):** B1 (shadow mode, coverage telemetry, drills), B7 (chaos on the link), B8/B9 (model deploy governance), B10 (drills through delivery), C12 (thresholds to govern), C13 (privacy-preserving telemetry), Decisions #4/#11/#17/#18/#20.
- **Depended on by (future):** Module 16 (regulatory change-control, validation evidence), the entire product's trustworthiness and the reliability moat.
- **RAXHA subsystem:** cross-cutting — the discipline that validates and monitors every other subsystem.
- **AI models consuming it:** none directly; validates/monitors all models + thresholds.
- **Sensors contributing:** none directly; tests the whole sensor→decision→delivery chain.
- **Assumptions for validity:** replay corpus includes real-world events; two-sided metrics; governed deploys; daily drills; privacy-preserving telemetry; test on release builds/real devices.
- **Confidence:** replay/chaos/shadow/drills/governed-deploys ★★★★★ / miss-surrogate observability ★★★★. See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Competency 14 pairing: **Digital Biomarkers & Digital Phenotyping** (Module 10) + **B13 — Architecture patterns (MVVM, Clean/Hexagonal, SOLID, DDD, DI, offline-first)**. Then the finale: **Medical AI, Clinical Validation & Regulatory** (Module 16) — where RAXHA's every claim meets the FDA.*
