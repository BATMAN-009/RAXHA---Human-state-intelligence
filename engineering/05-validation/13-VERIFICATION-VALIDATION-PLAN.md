# 13 — Verification & Validation Plan

> **Completes the traceability chain:** `Hazard → Risk Control → ADR → SRS → Interface → VV → Evidence Package → Release Decision.` Every "Verified By" in [10B](../03-safety/10B-RISK-CONTROL-MATRIX.md), every ADR "Verification" field (11), and every interface row (12) resolves here to a real `VV-` ID with an evidence artifact and an exit criterion.
>
> **Verification vs Validation (explicit, everywhere):**
> - **Verification** — *did we build it correctly?* (against spec: replay, chaos, performance, security tests)
> - **Validation** — *did we build the correct thing?* (against reality: shadow deployment, field drills' real-world half, usability, clinical studies)
>
> **Exit criteria per item:** `PASS` / `FAIL` / `BLOCKED` (dependency prevents execution) / `NOT-EXECUTED`. "Completed" is not a status.
>
> **VV ID blocks (method-first, per §organization):** VV-1xx Replay · VV-2xx Chaos · VV-3xx Field Drills · VV-4xx Shadow · VV-5xx Performance · VV-6xx Security · VV-7xx Privacy · VV-8xx Claims/Usability/Clinical. *(07B's `VV-D##` placeholders resolve to these — mapping in Appendix A.)*
>
> **Regression levels** (what must rerun for a given change):
> | Level | Scope | Reruns when |
> |---|---|---|
> | **L0** unit | pure-core unit tests | every commit |
> | **L1** architecture | replay determinism + contract tests (VV-1xx core, interface contracts) | every merge |
> | **L2** safety | full replay corpus + veto suite + chaos suite (VV-1xx/2xx) | any change touching Sensing→Response, models, thresholds |
> | **L3** release | L2 + drills + shadow gates + performance + privacy audits (VV-3xx/4xx/5xx/7xx) | every release candidate |
> | **L4** regulatory | L3 + full evidence-package assembly + assumptions review (B14/PCCP shape) | claim-bearing releases / periodic |

---

## §1 Replay Verification (VV-1xx) — *Verification · runs in CI against the pure core + shipped artifacts*

| VV | Test | Verifies (SRS · ADR · Hazard · IF) | Level | Evidence Package | Exit criterion |
|---|---|---|---|---|---|
| VV-101 | **Determinism**: identical traces ⇒ bit-identical decisions | SRS-402 · ADR-104/109 | L1 | determinism report (hash comparison) | PASS = zero divergence across full corpus |
| VV-102 | **Veto-contract suite**: no context configuration can zero a life-critical event | SRS-403, 1005 · ADR-104 · H-01 · IF-INT-04 | L1 (gate) | veto replay report | PASS = 100% of veto scenarios escalate; any suppression = FAIL, release-blocking |
| VV-103 | **Fall-corpus recall**: recorded+synthetic falls (incl. soft/atypical) end in ALERTING within budget | SRS-501/504 targets · H-01 | L2 | recall report per corpus segment | PASS = ≥ target recall per segment (targets set pre-run, D20) |
| VV-104 | **ADL false-alarm suite**: sit-down-hard/sports/treadmill traces do NOT alert | H-02 · ADR-103/104 | L2 | FA report per ADL class | PASS = FA rate ≤ per-class ceiling |
| VV-105 | **Unknown-widening**: degraded/missing modalities widen uncertainty, trigger check-in on alarming context | SRS-202, 404 · ADR-102 · H-01 | L2 | scenario report | PASS = no silent-normal on any degraded trace |
| VV-106 | **Reboot-mid-COUNTDOWN**: journal recovery resumes with correct remaining time; expired-while-dead fails toward alerting | SRS-501, 504 · ADR-105 · H-01/H-08 | L2 | FSM recovery report | PASS = correct resume/escalate on all reboot points |
| VV-107 | **Quantized-artifact rare-class**: the *shipped* int8/converted model meets rare-class recall | SRS-905 · ADR-109 · H-01 | L2 | artifact validation report | PASS = shipped artifact ≥ float-model recall − agreed delta |
| VV-108 | **Spoofed/faulty-input rejection**: implausible single-sensor injections don't dominate Risk | SRS-303 · ADR-103 · H-01/H-02 | L2 | robustness report | PASS = no single-channel injection flips the decision |
| VV-109 | **Pre-event buffer**: ≥10 s pre-trigger context present at confirmer | SRS-1003 · ADR-101 | L1 | buffer audit | PASS = 100% of triggers carry full pre-window |
| VV-110 | **Contract tests**: every IF-* interface's producer/consumer honor contract version + failure semantics | 12 matrix · ADR-101…106 | L1 | contract test report | PASS = all 19 interfaces conform |

## §2 Chaos Verification (VV-2xx) — *Verification · fault injection on staging/devices*

| VV | Test | Verifies | Level | Evidence Package | Exit criterion |
|---|---|---|---|---|---|
| VV-201 | Live reboot mid-incident (device) | SRS-501/502 · H-01/H-08 | L2 | chaos log + FSM trace | PASS = incident resumes or dead-man covers |
| VV-202 | Watch↔phone link loss during escalation | IF-PLT-04 · SRS-503 | L2 | chaos log | PASS = queued, deduped, no loss/duplicate |
| VV-203 | Network loss: decision + local delivery offline | SRS-301 · ADR-105/106 · D02 | L2 | offline scenario log | PASS = decision unaffected; SMS/local paths fire |
| VV-204 | Cloud outage: persist-first ingest, no alert loss | SRS-601 · H-03 | L2 | outage replay log | PASS = zero lost events after recovery |
| VV-205 | Telephony/push vendor outage → failover | SRS-604 · ADR-106 · H-03 | L3 | failover report | PASS = delivery via secondary within rung timeout |
| VV-206 | Duplicate/replay storm → exactly-once effect | SRS-503 · IF-NET-01 · H-06 | L2 | dedup metrics | PASS = zero duplicate Alerts at any storm rate |
| VV-207 | Battery death mid-incident → dead-man escalation | SRS-602 · H-01 · IF-NET-02 | L2 | dead-man activation log | PASS = server-side escalation fires on heartbeat loss |
| VV-208 | Permission revocation mid-operation → honest degradation | SRS-703 · H-04 | L2 | coverage-state log | PASS = protection level re-labeled + surfaced |

## §3 Field Drills (VV-3xx) — *Verification of the live pipeline; Validation that production actually works*

| VV | Test | Verifies | Level | Evidence Package | Exit criterion |
|---|---|---|---|---|---|
| VV-301 | **Daily synthetic incident** end-to-end (device→cloud→ladder→ack) | SRS-605 · H-01/H-04/H-08 | L3 + continuous | drill log (daily) | PASS = drill completes; any failure = Sev-1 |
| VV-302 | Full-ladder climb incl. voice rung | SRS-505 · IF-NET-03/04 | L3 | ladder transcript | PASS = each rung fires on ack-timeout |
| VV-303 | Dead-man drill (kill device mid-synthetic-incident) | SRS-602 · H-01 | L3 | drill log | PASS = server escalation, no duplicate (reconciliation) |
| VV-304 | Location-share click-through + expiry | SRS-801 · IF-NET-05 | L3 | share lifecycle log | PASS = live during incident, dead after resolution |
| VV-305 | Audit-completeness: reconstruct the drill *why* from records alone | SRS-904 · H-08 | L3 | audit reconstruction report | PASS = full chain reconstructable, versions present |

## §4 Shadow Validation (VV-4xx) — *Validation · real fleet, silent decisions*

| VV | Test | Validates | Level | Evidence Package | Exit criterion |
|---|---|---|---|---|---|
| VV-401 | Real-world FA rate per wearer-week | SRS-902/903 · H-02 · D08 | L3 (gate to enable alerts) | shadow FA report | PASS = ≤ target FA/wearer-week over the shadow window |
| VV-402 | Miss-surrogate monitoring (paired with VV-401 — never one-sided) | SRS-903 · H-01 · D20 | L3 | two-sided metric report | PASS = surrogate within bounds *and* reviewed with FA |
| VV-403 | Field calibration: reliability diagrams/ECE vs shadow ground truth | SRS-205 · ADR-108 · H-01/H-02 | L3 | calibration report | PASS = ECE ≤ target; else recalibrate before release |
| VV-404 | Baseline maturity/personalization behavior on real wearers | SRS-203/204 · ADR-102 | L3 | baseline cohort report | PASS = no pathology-absorption signature; cold-start honest |
| VV-405 | Coverage-equity: shadow population vs deployment population representation | D21 corollary · H-01 | L3/L4 | representation report | PASS = monitored segments within bounds; gaps documented |
| VV-406 | Threshold/model change gate: paired-metric shadow comparison pre-canary | SRS-901 · ADR-112 · H-01/H-02 | L2 per change | change-evidence pack | PASS = no miss-surrogate regression for any FA gain |

## §5 Performance Measurement (VV-5xx) — *Verification*

| VV | Test | Verifies | Level | Evidence Package | Exit criterion |
|---|---|---|---|---|---|
| VV-501 | Pipeline p99 < 500 ms (Evidence→Decision, ex-countdown) | SRS-1001 · D07 | L1 regression | latency histogram | PASS = p99 within budget on target hardware |
| VV-502 | Trigger→first-notification & →ack p99 | SRS-1002 · H-03 | L3 | latency histograms | PASS = p99 within targets (set + versioned here) |
| VV-503 | Battery per-mode budget (always-on, armed, incident) | SRS-1004 | L3 | power measurement table | PASS = each mode within budget on device matrix |
| VV-504 | Wake-path latencies (gyro spin-up, location pre-warm hit-rate) | ADR-101 · C6/§13 | L2 | wake-latency report | PASS = line-items within blueprint budget |
| VV-505 | Heartbeat SLO (delivery rate, gap distribution) | IF-NET-02 · Blueprint risk #4 | L3 + continuous | heartbeat SLO dashboard | PASS = gap p99 below dead-man threshold margin |

## §6 Security Validation (VV-6xx) — *Verification + adversarial validation*

| VV | Test | Verifies | Level | Evidence Package | Exit criterion |
|---|---|---|---|---|---|
| VV-601 | Penetration test (device, cloud, share links) | SRS-803 · H-09 | L4 periodic | pen-test report | PASS = no critical/high findings open |
| VV-602 | Key non-exportability (hardware-backed) | SRS-803 · ADR-111 | L3 | key-audit report | PASS = extraction attempts fail on-device |
| VV-603 | Unsigned/tampered config+model rejection | SRS-803/901 · IF-NET-06 · ADR-112 | L2 | rejection test log | PASS = 100% unsigned artifacts refused |
| VV-604 | Boot-journal tamper evidence | ADR-105 · H-08 · C3 resolution | L3 | tamper test report | PASS = forged journal detected (TEE-key or cloud-authoritative) |
| VV-605 | Spoofed-incident ingest (authn) | SRS-601-auth · H-06/H-07 | L2 | authz test report | PASS = non-device-originated incidents rejected |

## §7 Privacy Validation (VV-7xx) — *Verification (audits) + Validation (real flows)*

| VV | Test | Verifies | Level | Evidence Package | Exit criterion |
|---|---|---|---|---|---|
| VV-701 | Data-flow audit: raw never leaves device; events-only to cloud | SRS-105 · ADR-111 · H-09 | L3 | data-flow audit report | PASS = zero waveform-class fields cross-tier |
| VV-702 | Retention: purge-on-resolve verified; no history accumulation | SRS-801/804 | L3 | retention audit | PASS = post-resolution queries return nothing |
| VV-703 | No location in URLs/logs | SRS-802 | L1 (lint) + L3 | log/URL scan report | PASS = zero occurrences |
| VV-704 | Share-token expiry enforcement | SRS-801 · IF-NET-05 | L3 | expiry test log | PASS = expired tokens dead in ≤ grace |
| VV-705 | Consent gate: no Alert to non-`accepted` contact | SRS-805 · H-07 | L2 | consent test report | PASS = 100% blocked |
| VV-706 | Schema audit: no sellable location/health store exists | SRS-804 · D21 | L4 periodic | schema audit report | PASS = attestation with schema inventory |

## §8 Claims, Usability & Clinical (VV-8xx) — *Validation · honestly scoped to the claims ladder (PDR-005, C15)*

| VV | Test | Validates | Level | Evidence Package | Exit criterion |
|---|---|---|---|---|---|
| VV-801 | **Claims-language audit**: every user-facing string within the Boundary (D22) + exact coverage-promise wording (PDR-007) | SRS-1103 | L3 | content audit report | PASS = zero diagnostic/therapeutic/"always detect" claims |
| VV-802 | **Elder usability**: countdown cancel, check-in, SOS operable by target users incl. under simulated stress | SRS-1104, 406 · IF-HUM-01/02/03 | L3 | usability study report | PASS = task success ≥ target with 65+ participants |
| VV-803 | **Family responder usability**: alert comprehension, ack flow, location-uncertainty understanding | IF-HUM-04/05 · D15 | L3 | usability report | PASS = responders correctly interpret + act |
| VV-804 | **Clinical validation program** — **DEFERRED by design**: v1 makes no medical claims (PDR-005), so no clinical trial exists to run. This item pre-registers the V2+ program: target-population prospective validation (V3 clinical axis, C14/C15) required *before* any cleared claim. | C15 claims ladder | L4 (future) | protocol registered; **status: NOT-EXECUTED (by design)** | Gate: opens only when a medical claim is pursued |

---

## Appendix A — 07B placeholder resolution (`VV-D##` → real IDs)

VV-D02→VV-203 · VV-D03→VV-101 · VV-D06→VV-206 · VV-D08→VV-401/406 · VV-D09→VV-208 (+ coverage dashboards) · VV-D11→VV-106/207/303 · VV-D13→VV-105 · VV-D16→VV-404 · **VV-D17→VV-102** · VV-D18→VV-403 · VV-D19→VV-401+402 (paired) · VV-D20→VV-301/402/406 · VV-D21→VV-701–706 · VV-D22→VV-801. *(Remaining D-rows map to audits noted in their 07B rows.)*

## Appendix B — Traceability chain, closed (worked examples)

```
H-01 (missed emergency) → 10B veto control → ADR-104 → SRS-403 → IF-INT-04 → VV-102 → veto replay report → L1 release gate
H-04 (silent coverage)  → 10B drill control → ADR-110 → SRS-605 → IF-NET-02 → VV-301/303 → drill logs → Sev-1 policy + L3 gate
H-09 (privacy breach)   → 10B minimization  → ADR-111 → SRS-105/801 → IF-NET-05 → VV-701/704 → audit reports → L3/L4 gate
```
The complete matrix (every hazard control → its VV row) is maintained as a generated table from 10B×13; a control with no VV, or a VV with no upstream, is a defect in whichever document dropped the thread.

## Release Decision rule

A release ships only when: **(1)** its regression level's VV set shows no `FAIL`/`BLOCKED`; **(2)** every `No`-observable hazard (10A) has *fresh* manufactured evidence (VV-301+ drills, VV-401/402 shadow) inside its validity window; **(3)** two-sided metrics reviewed together (VV-401+402 — never one alone); **(4)** the Validation Assumptions Register (below) has no red assumption. Evidence packages are archived per release — the future regulatory evidence set (B14/PCCP shape).

---

## Validation Assumptions Register (VA)

> Many safety failures occur not because implementation is wrong but because **an assumption silently stopped being true.** Every VV item leans on assumptions; they are registered, owned, and re-checked — an assumption going red blocks the releases that depend on it.

| VA | Assumption | Depended on by | Risk if false | Re-check trigger / monitor |
|---|---|---|---|---|
| VA-01 | The replay corpus represents real-world falls/ADLs | VV-103/104/107 | Verified-correct system fails in the field (lab-vs-life, SisFall→FARSEEING) | Corpus refreshed from shadow traces each quarter; divergence review |
| VA-02 | Simulated/synthetic falls approximate field falls of *elderly* wearers | VV-103 | Recall numbers overstate protection for the target population | Compare against confirmed real incidents as they accrue; FARSEEING-class benchmarks |
| VA-03 | Shadow population ≈ deployment population | VV-401–405 | FA/miss/calibration estimates biased against underrepresented users (C13 FL-bias echo) | VV-405 representation report each release |
| VA-04 | Calibration transfers across time/OS-updates/hardware revisions | VV-403 | Confidence silently decays → Risk math wrong (Blueprint risk #1) | Scheduled reliability re-runs; post-OS-update L2 |
| VA-05 | Drill path ≡ real-incident path (no drill-only shortcuts) | VV-301–305 | Drills go green while the real path is broken | Code audit: drill uses production path with a synthetic flag only at ingress/egress |
| VA-06 | Miss-surrogates track true misses | VV-402 | Invisible under-protection despite green dashboards (Blueprint risk #5) | Re-anchor against reported/confirmed events; periodic surrogate review |
| VA-07 | Heartbeat channel reliability exceeds dead-man threshold margins | VV-207/303/505 | Dead-man false-fires or sleeps through real death | VV-505 continuous SLO |
| VA-08 | Elder usability results (lab) hold under real stress/impairment | VV-802 | Cancel/check-in unusable exactly when needed | Post-incident UX review of every real cancel/ack; iterate |
| VA-09 | Platform behaviors (background, entitlements, sensor access) persist across OS releases | VV-1xx/2xx assumptions · D12 | Silent capability loss → coverage gaps | Re-verify on every OS beta (platform-truth ritual); L2 rerun |

---

**The standing question:** *could a new engineer execute this V&V program and assemble a release-evidence package using only this document and its upstream references?* Any gap discovered gets fixed here, not in someone's head.

*Next: 14 — Implementation Roadmap (the last document before code).*
