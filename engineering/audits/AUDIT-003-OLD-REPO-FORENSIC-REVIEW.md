# AUDIT-003 — Forensic Review of the Predecessor Repo (`Watch_App_Companion_App_Claude`)

> **Commissioned by the founder 2026-07-21** ("use the repo as evidence for the new system, not as the system itself"), optimized for **migration planning** (founder's explicit choice). Method: four parallel read-only forensic passes (watch safety path / phone + bridge / backend + ops / history + docs mining), every claim file:line-cited in the appendix sub-reports, FACT vs INFERENCE vs UNKNOWN separated. Repo: github.com/vin66sag/Watch_App_Companion_App_Claude, 1,157 commits (2026-01-15 → 2026-07-21, HEAD V922), ~47k LOC Swift + 24 Deno edge functions + 75 SQL migrations + Next.js ops console. **Nothing in the old repo was modified.** Trigger (four-trigger rule): Reality — a real predecessor artifact entered evidence.
>
> Companion file: [AUDIT-003-APPENDIX-SUBREPORTS.md](AUDIT-003-APPENDIX-SUBREPORTS.md) — the four full sub-reports with all citations.

---

## A. EXECUTIVE SUMMARY

**What the repo is:** the previous iteration of this company. Born "Suraksha Companion App" (React Native, 2026-01-15), pivoted native Swift within a week, renamed **Raxha** (2026-02-12), **shipped on the App Store** (1.0.0 submitted 03-17 → rejected → resolved; **1.0.1 and 1.0.2 approved**; 1.0.5 submitted 07-08 under Raxha, Inc.; 1.0.5/1.0.6 outcomes unrecorded). Fleet ≈ the founder's household (the HR-retrain job has a hardcoded two-user map: "userA (you) / userB (sister)").

**What the app actually does today:** watch-side continuous HR/HRV/motion monitoring kept alive by an `HKWorkoutSession`; heuristic fall detection (2 Hz accelerometer, impact-threshold × activity multiplier + post-impact stillness staging); mic auto-activation on elevated vitals feeding on-watch VAD/keyword-spotting + SoundAnalysis + a cloud voice pipeline (raw 10s WAV → Sarvam/ElevenLabs STT → keyword-lexicon MAX-fused with an Anthropic LLM verdict); a 5-second-timer threat-score fusion driving a 10s cancelable SOS countdown; dual-route SOS dispatch (phone relay + direct Supabase) with real idempotency; family map dashboard, server-side geofencing, managed child accounts with Aadhaar/DigiLocker parental verification; Supabase backend with genuinely hardened RLS; read-only ops console.

**Its true product shape:** a shipped guardian-buyer family-safety product, mid-pivot. The 2026-06-24 survey in the repo — *"the buyer is a guardian… 'myself' came last (8%/9%); India→eldercare, USA→child safety"* — is the fork whose India-eldercare branch **is the new RAXHA**. The old repo is not a different product; it is v0 of the same decision path.

**The five most important conclusions:**

1. **The old repo is independent, dated, field-generated proof of nearly every bet in the new architecture.** Persisted deadlines (ADR-105), the veto contract (D17/RFC-003), the dead-man switch (D11/H-04), the delivery ladder + post-ack loop (ADR-106/H-03/AUDIT-001-H4), calibrated confidence (D18), minimization (D05), no-LLM-in-decision-path (D03) — each corresponds to a *specific, dated failure or absence* in the old system (§C/§F). The new architecture was derived independently; this repo is the wound-record that validates it.
2. **The deepest pattern is the tested-brain / untested-wiring inversion.** `RaxhaWatchLogic` holds 263 tests over pure, well-argued policies — including an 11-state `SOSStateMachine` with the invariant *"help is on the way only when cloud-ACKed"* — and it was **never wired in**. The shipping countdown is a SwiftUI view's `@State var countdown = 10` whose latch clears on *any* dismissal, including system teardown. Meanwhile the 25.5k-LOC app target that actually decides life-or-death has **zero tests**. The old repo's own June audit said it on build 498: *"affordances that read as protective but don't actually function."* This is the same failure class AUDIT-002 found in the new verifier — the gate that can't fail — and it is the single thing the new process exists to prevent.
3. **"Always-on" is conditional and the platform truths are now harvested.** Protection ≡ workout session alive; wrist-off intentionally ends the session; recovery is a best-effort ladder (HKObserverQuery + Background App Refresh that "may still be skipped" + CMSensorRecorder retro pickup + phone remote-start). Six months of production yielded platform evidence the new Evidence Register wants: BAR delayed 37+ min observed; on-wrist staleness p95 = 295.5s; a 1h45m silent protection blackout at low battery; CMSensorRecorder usable only retrospectively (corroborates E-04/E-05 exactly).
4. **A real decision-latency defect shipped and was never caught by tests — only by field incidents.** The threat loop counts ticks (5s) as seconds: "30s sustained" is actually **150s**; "5s critical" is **25s**. The café false-SOS timeline in the repo's own logs matches the inflated math. No unit test could see it (the policies are correct in isolation); a deterministic replay harness (VV-101-class) would have. This is the strongest single justification for the new Phase-0 harness-first build order.
5. **Migration = wire the old brain into the new spine — never port the old app.** Salvage the tested policies, the field-calibrated constants, the proven patterns (idempotent dual-route dispatch, persist-before-notify, RLS suite), and the lessons. Discard the wiring: the fused scorer, the view-owned countdown, the config-disabled detection layers, the flag-soup. The new Phase-0 core (FSM with persisted deadlines, deterministic replay, contracts) is precisely the organ the old system lacked.

---

## B. SYSTEM MAP (condensed — full detail in appendix)

**Watch app** (`ios/Raxha Watch App`, ~25.5k LOC, 0 tests): `HealthKitManager` (workout-session HR + wake ladder) · `MotionManager` (2 Hz impact/fall + wrist/table FSM) · `ThreatDetectionManager` (5s fusion loop, weighted score → safe/elevated/high/critical) · `MonitoringCoordinator` (mic auto-activation, check-ins) · `SoundAnalysisManager`/`VoiceKeywordGate`/`SileroVAD` (single shared mic graph) · `CloudSyncManager` (Route B direct Supabase + offline queue max 500) · `WatchConnectivityManager` (Route A phone relay) · `RedesignSOSView` (the countdown). Four CoreML packages; FallDetector CNN + 50 Hz IMU stream + Apple fall detection all **disabled by config** — three advertised layers, one live at runtime.

**Pure logic SPMs** (tested): `RaxhaWatchLogic` (~2.5k LOC, **263 tests**: SOSStateMachine, VitalsOnlyEscalationPolicy, VoiceEvidencePolicy, ThreatEvidenceMicPolicy, CheckInPolicy, AutoActivationEngine, WatchCloudPayloads 33-test frozen contract) · `RaxhaML` (BaselineHR Gaussian table, 19 tests) · `RaxhaWatchUI` (pure screens, 7 test files).

**Phone app** (`ios/raxhamobile`, ~32.5k LOC): `WatchConnectivityManager` 3,706-line main-thread monolith — staleness tiers 180/240/300/600s, replay gates 120s, SOS freshness 300s (constants encode ~40 field incidents) · voiceWindow relay scoring in parallel (cloud STT + on-device SpeechAnalyzer/FoundationModels, `en_IN` hardcoded) · `PhoneSOSCoordinator` (shared-`sos_id` relay; single-shot, no retry) · `DatabaseManager`/`SupabaseManager` (server-truth reads, 4s foreground family poll) · passive trip stack (significant-change ↔ continuous GPS ladder) · diagnostics with the app's **only** durable offline queue. Family-side emergency UI: **dead code, zero call sites**.

**Backend** (`supabase/`): persist-before-notify SOS with client-UUID `ON CONFLICT DO NOTHING` dedup → APNs to parents + optional Twilio SMS (silently skipped if unconfigured) + opt-in nearby blast. **No incident entity, no FSM, no acks, no retries, no ladder, no voice calls, no dead-man watchdog.** Hardened RLS (two real cross-family breaches found + properly fixed), granular consent columns, location-masking reveal rule (family-mode OR active-SOS), pg_cron retention (which silently didn't run for ~10 weeks — pg_cron absent on prod). Voice: raw audio → Sarvam/Saaras or ElevenLabs → keyword lexicon MAX-fused with **`claude-haiku` LLM verdict** (345 silent failures unnoticed for weeks). `voice-distress-ml` = hand-rolled pseudo-models; `vertex-predict` = unused open cost hole. Weekly retrain crons real but 2-user scale.

**Sensors used:** HR/HRV (HealthKit), accelerometer 2 Hz (+dormant 50 Hz), CMMotionActivity, mic (event-activated), GPS (watch + phone fallback), barometer/proximity **not used**. Wrist state via luminance + variance + HR-phantom corroboration.

## C. ARCHITECTURE REVIEW

**Actual pattern:** singleton managers + `@Published` flags + timers, with an admirable late-era effort to extract pure tested policies into SPM packages that the app then largely didn't consume. No dependency injection at the wiring layer, no FSM in the live path, no replay/determinism anywhere (wall-clock `Timer`s throughout).

**Genuinely clean:** the extracted policy layer and its tests; the frozen `WatchCloudPayloads` contract; Route A/B dispatch with idempotency and the V330 "paired watch always fires Route A" floor; the RLS/consent/masking schema; the diagnostics queue design; the decision-record + Q&A process (established 07-06); `tasks/lessons.md`.

**Fragile / violates safety-critical design (each with evidence in appendix):**
- Countdown state lives in a view; **no persisted deadline anywhere**; reboot or scene teardown mid-countdown silently erases the SOS.
- **Context suppresses life-critical events**: Table-Mode GATE 1 blocks *all* auto-SOS including detected falls and panic words; the var<0.001 stillness veto cancelled a real detected fall 27s after impact (the repo's own field note). "Machine-like stillness" is also an unconscious wearer's profile. — Direct, field-dated proof of D17/RFC-003.
- **Tick-vs-seconds ×5 latency inflation** in the sustained-threat path (conclusion A4).
- **Dual `ThreatDetectionManager` instances**: telemetry, dashboards and resume-sync read a dormant `.shared` brain that is not the deciding instance.
- Uncalibrated confidence everywhere; ad-hoc formulas; the 0.374 untrained-model intercept "testified against the wearer" in two false-SOS incidents; `unknown` folded into booleans.
- Delivery is fire-and-forget past persistence: `pushesSent:0, smsSent:0` still returns `ok:true`; the failure surfaces nowhere.
- LLM (claude-haiku) in the distress verdict; raw audio + transcripts across three external vendors, retention unconfirmed (their own release checklist blocked the privacy claim as "not yet true").

**Hidden assumptions (labeled in appendix):** workout-write permission granted; BAR fires; phone reachable for token refresh (standalone Route B decays when the token expires); locale ≈ spoken language (a Telugu emergency routed to the wrong STT by an en-US locale); human wrists always jitter; check-ins get answered; consent toggles in sync across devices.

## D. HUMAN-STATE-INTELLIGENCE GAP ANALYSIS

Where the old repo stops being an app and fails to be an HSI system:

- **No `HumanState`.** Signals feed a weighted score directly; there is no canonical fused state object, no posture/motion/place context model beyond geofence membership, no baseline maturity, no contributing-evidence provenance.
- **No state/anomaly/risk/policy separation.** The 5s fusion loop collapses evidence→risk→policy→UI into one scorer + gates. Policies that *should* modulate risk instead veto action (GATE 1) — the exact confusion D17 exists to forbid.
- **No calibration layer; no first-class unknown.** Confidence is raw model output or hand formulas; absence of evidence becomes 0 or a gate default, not a widened-uncertainty state (VV-105's direction is absent).
- **No degraded-mode honesty.** Protection state is boolean; the 1h45m battery blackout was silent to wearer and guardian alike; there is no Coverage concept, no cause-attributable degradation, no dead-man backstop.
- **No replay/determinism.** Wall-clock timers, singleton mutation, main-thread fusion — the tick/seconds bug lived here precisely because behavior was untestable end-to-end.
- **Scenarios where it cannot be expected to work** (from code, not speculation): reboot mid-countdown; unconscious-still wearer in table-adjacent stillness; standalone watch after token expiry; guardian with app backgrounded (4s poll dead, family alert UI dead code); low battery below the silent pause; any failure of the single APNs channel when Twilio is unconfigured.

## E. REUSABILITY (framed as migration inputs — what each contributes to the new build)

**Lift as evidence/spec (highest value, zero code risk):**
- **Field-calibrated constants**: staleness tiers (180/240/300/600s; p95=295.5s), replay-freshness gates (120s/300s), impact thresholds ×activity multipliers, stillness windows (8/20/45s), 30s voice-relay deadline + 300s keep-alive, mic debounce values. These are numbers reality tuned — seed values for the new corpus and SRS targets.
- **Platform truths → Evidence Register**: workout-session-keeps-process-alive; BAR skippable (37+ min observed); CMSensorRecorder retro-only (corroborates E-04/E-05); observer-query wake ladder; single-mic-graph constraint; charging detectable only by polling; two-CMMotionManager risk.
- **Field incidents → replay corpus scenarios**: café false-SOS (silence testimony), club false-SOS (children_shouting 90%), shout-discarded-by-deadline, battery blackout, phantom-HR table cases, real fall cancelled by stillness veto. Each becomes a named trace the new VV-103/104 suites must pass.
- **Lessons + process**: `tasks/lessons.md` verbatim; the decision-record + Q&A mandate; protected-algorithms regime; "revert don't fix forward"; "user's physical observation is ground truth."

**Lift as tested logic (port with contracts, re-home on the new spine):** `SOSStateMachine` (11 states + invariants + 12 tests — *and this time wire it*); `VoiceEvidencePolicy` (words-over-melody veto + no-evidence floor); `VitalsOnlyEscalationPolicy` + `CheckInPolicy` + `ThreatEvidenceMicPolicy` (fix the seconds contract); `WatchCloudPayloads` frozen contract; BaselineHR Gaussian-table approach (interpretable, confidence-gated); Silero VAD integration + conversion scripts.

**Lift as pattern (re-implement clean):** persist-before-notify + client-UUID idempotency; dual-route dispatch with the always-fire-Route-A floor; the RLS hardening suite + masking reveal rule + consent-column granularity (RFC-007 design library); the diagnostics durable-queue design **applied to SOS this time**; single-refresh-authority auth (minus refresh-token forwarding); read-only ops console; rate-limit RPC.

**Discard:** the fused threat scorer implementation; the view-owned countdown; `voice-distress-ml` pseudo-models; `vertex-predict`; `RaxhaDiagnostics` canned "AI patch"; dual-instance wiring; the 3.7k/3.0k-line god objects; Apple-fall-detection dead branch (until the entitlement exists — A1); dormant CNN stack (**unknown** provenance, zero tests — treat as unvalidated candidate, not asset).

## F. FAILURE ANALYSIS (the founder's matrix)

| Condition | What actually happens (evidence-backed) |
|---|---|
| **Watch absent** | No detection at all; phone contributes passive trip tracking + manual SOS only. |
| **Phone absent** | Watch Route B works *while* a Supabase token is fresh; token refresh requires the phone → standalone delivery silently decays; "NO VIABLE ROUTE… SOS CANNOT be delivered" goes to a debug log, wearer never told (the unwired `sendFailed` state would have shown it). |
| **Background limited** | Everything rides the workout session; on wrist-off the session is intentionally ended; recovery = best-effort BAR/observer ladder; countdown/timers die with the process; no persisted deadline resumes anything. |
| **Sensors/permissions missing** | Partial degraded modes exist (observer-only HR); HealthKit revocation only *inferred* after 15 min of silence; notification permission assumed for every safety surface; no Critical Alerts entitlement — SOS relies on time-sensitive + custom sound. |
| **Delivery unavailable** | `ok:true` with zero notifications is a reachable, silent state (Twilio unset → skipped; all pushes fail → 200; fan-out lookup fails → `partial`). No acks, no retries, no ladder, no voice. Family-side full-screen alert is dead code; guardian sees a banner + a 4s foreground poll. |
| **Precision poor / confidence low** | Uncalibrated scores fused with hand weights; untrained-model intercept pushed *toward* SOS on silence; low-confidence never widens to check-in-with-uncertainty — it either gates or testifies. |

**Top failure modes, ranked by hazard:** (1) countdown non-persistence → H-01; (2) stillness/Table veto of real falls → H-01, D17; (3) silent delivery failure + no family-side UX → H-03/H-04; (4) tick×5 latency inflation → H-03; (5) silent battery blackout → H-04; (6) standalone token decay → H-01 for the watch-only elder — **directly relevant to RFC-005's Family-Setup shape**.

## G. MIGRATION PLAN (into the new RAXHA)

**Use immediately (no founder decision needed):**
1. Convert the field incidents (§E) into named replay traces with expected outcomes — the first real (non-synthetic) corpus entries, retiring part of TD-4.
2. File the platform truths into the Evidence Register with citations to this audit (several 🔴/🟡 rows gain production-grade corroboration; E-04/E-05 effectively double-confirmed).
3. Adopt the constants as provisional SRS/threshold seeds, each marked "field-calibrated in predecessor, revalidate on elder population."
4. Mine `lessons.md` + the June audit into the V&V mindset (most are already independently encoded in the new docs — noting the convergence is itself evidence the doctrine is right).

**Founder decisions this audit sharpens (queue, not new items):** RFC-001/002 (the old repo *proves* own-sensing fragility and has no native-fall coordination — it never got the entitlement: A1's urgency demonstrated); RFC-003 (the fall-cancelled-by-stillness incident is the veto-contract smoking gun); RFC-004 (battery blackout = the charging-hole evidence); RFC-005 (standalone token decay defines the watch-only elder's true requirements); RFC-007 (the consent schema + guardian-centric role model is the starting design library); RFC-008 unchanged.

**Explicitly avoid repeating:** shipping affordances before wiring is proven end-to-end; testing the policies but not the spine; config-flag graveyards presented as "layers"; default-ON for sensitive data before legal; claims ("always-on", "16-second SOS") ahead of measurements; letting the journal fragment; fleet-of-one telemetry read as validation.

**Do not:** port the app; adopt its Supabase project/schema wholesale; inherit the LLM-in-path voice verdict; carry the raw-audio cloud pipeline into v1 (D05 forbids it; their own checklist blocked its privacy claim).

## H. QUESTIONS FOR THE FOUNDER (evidence cannot answer these)

1. **What was the App Review outcome of 1.0.5 (build 12) and 1.0.6?** Unrecorded in the repo through 07-21.
2. **Are there real external users on the App Store build right now?** (Ops docs suggest single digits; retrain map says two.) This decides whether the old app is a live obligation or a closed chapter.
3. **Does the old app stay live while the new RAXHA is built** — and if so, who maintains it? (Dual-maintenance is a real cost; the V918–V922 minors sprint suggests active feature pressure.)
4. **Does the new RAXHA inherit the entity, App Store listing, and brand** (Raxha, Inc., the existing app record), or launch clean?
5. **What is the legal state you're carrying:** Sarvam DPA signed? counsel review of ToS v1.2/v1.3? the DPDP minors question (enforcement 2027-05-13)? These gate any reuse of the voice pipeline and the minors flow.
6. **DigiLocker/MeriPehchaan partner registration** — was it ever obtained (credentials absent from repo say no)? Does the new RAXHA need the VPC stack at all for the elder beachhead?
7. **Which backend stays running?** Same Supabase project for the new system, or clean project + selective schema lift? (Free-tier 500MB, ~188MB used; pg_cron gap history.)
8. **What hardware exists from the old project** (watch models, the Ultra 3 mentioned in January) — does any of it satisfy the SPIKE-002 kit (cellular Series 9/10 + Series 4/SE + test iPhone + eSIM)?
9. **May the old production telemetry** (user_events, hr_snapshots, sos_decision_metrics, staleness episodes) **be exported as corpus seed data** — and whose consent covers that (it's your household's data)?
10. **Is the old repo's fleet a candidate shadow-mode pilot** for the new system (same two wearers, new engine in shadow), or do you want a hard break?

---

## ADDENDUM (2026-07-21) — Founder answers to §H + delegated decisions

**Snapshot boundary:** this audit reads the repo **as of V922 (`5c075c4a`)**. Same-day commits V923–V925 landed after the clone (minors/VPC sprint continuing: adults-only gate removed — Child/**Elder** unblocked in Add Member — buildTag freshness fix, consent-before-processing pairing gate). The live track is actively moving; findings above are stamped to the snapshot, per the freshness discipline.

**Founder's answers (facts on the record):**
1. **1.0.6 was released and is LIVE on the App Store.** 2. **Real external users exist.** 3. **The old app stays live until the new RAXHA replaces it** (dual-track until cutover). 4. **The new RAXHA inherits the entity, App Store listing, and brand — and launches clean** (identity continuity, clean codebase). 5. **Legal is clear** — founder attests both-side documentation complete (supersedes this audit's UNKNOWNs on DPA/ToS state). 6. **DigiLocker/VPC stays, India-only.**

**Decisions delegated to the pair architect ("go with your decision — future-proof + present position") and taken as follows:**

- **D-A3.1 Backend: CLEAN new Supabase project for the new RAXHA; the old project keeps serving the live app untouched.** Rationale (dominance): the old project is *production for real users of a safety product* — coupling a new build to it risks the shipped system; the new doctrine-shaped schema (Incident FSM, EventEnvelope, uncertainty+age locations) is structurally incompatible with the old fat-`profiles` model; the old project carries free-tier limits and the pg_cron outage history. What migrates is **patterns** (RLS hardening suite, masking reveal rule, consent granularity, persist-before-notify, idempotent dedup), not the database. User migration happens once, at cutover, via an export path. Revisit-trigger: if cutover design shows account continuity demands shared auth, revisit *auth only*, never the data plane.
- **D-A3.2 Hardware: follow the SPIKE-002 kit as specced** (cellular Series 9/10 + budget Series 4/SE + test iPhone + eSIM); any owned device that matches a slot is reused, gaps are purchased — physical procurement is the founder's action. Rationale: the kit was designed to answer E-06/07/08; nothing in this audit changes it.
- **D-A3.3 Old-app telemetry → corpus seed: YES, export with consent provenance + minimization** (events/features only; no raw audio — none is stored anyway). Why it's needed (founder asked): real-wearer traces are the scarcest asset in this field (the TD-4/FARSEEING problem); this is the only real-human data the company owns, with consent (founder's household), and it converts six months of production into replay traces the calibrated verifier can hold as regression floor. Named field incidents (café, club, shout-deadline, battery blackout, stillness-veto fall) become the first non-synthetic VV-103/104 scenarios.
- **D-A3.4 Shadow pilot: the old fleet (household) is the designated first shadow cohort at Phase S** — silent, zero-risk, highest-value wearers. Recorded as intent; activates at Phase 8/S per the roadmap, not now.
- **D-A3.5 VPC international (founder's question answered):** the elder beachhead needs **no VPC at all** in v1 (adults). If/when minors go international: US = COPPA-sanctioned verifiable-parental-consent methods (ID+selfie or payment-card verification via vendors such as Persona/Stripe Identity/PRIVO-class), EU/UK = age-assurance under GDPR-K/AADC with similar ID vendors. The India module is already cleanly separable (three seams per the backend sub-report) — keep it a pluggable verification provider interface, ship India-only.

**Evidence-register effect:** this audit + answers corroborate E-04 (CMSensorRecorder retrospective-only — production-confirmed) and E-05 (always-on own sensing infeasible; workout-session-alive is the real invariant — production-confirmed); battery/BAR/staleness numbers recorded as *prior-generation device evidence* (E-14/E-15/E-16 stay open — different device class and wearer population than the elder target).
