# AUDIT-001 — Independent Pre-Phase-0 Product Review (2026-07-14)

> Adversarial first-principles audit of the PRODUCT as designed (not the documentation). Conducted at founder request before any production code. This file is the durable record; chat is disposable. Findings feed the [RFC Register](../rfcs/RFC-REGISTER.md). Category: review evidence (permitted under the four-trigger rule — this *is* the Reality/Evidence mechanism operating pre-code).

## VERDICT
**Build — but not exactly as designed.** Five changes required before Phase 0 (→ RFC-001…005); three external-dependency clocks must start immediately (→ Actions A1–A3). The architecture's independence doctrine (ADR-002/004) is correct for *decisions*, but **v1's *data* is a tenant on Apple's land** — three of five critical issues are consequences of designing as if that weren't true. The moat is real but lives in **Coverage Assurance + the post-ack response loop + the agency channel**, not where the documents spend the most pages.

## CRITICAL
- **C1 — On-watch detection layer likely platform-infeasible in v1.** Third-party watchOS apps get no sustained background runtime outside workout sessions; `CMSensorRecorder` is retrospective/minutes-delayed (useless for live confirmation). Real v1 engine = **platform fall event + phone-side context**, not the drawn always-on ring buffer + on-watch TinyML confirmer (Blueprint A3, ADR-101). → RFC-001. *Verify with a 2-week platform spike before anything else.*
- **C2 — Two-countdown collision.** Apple's fall detection shows its own unsuppressible full-screen alert + SOS countdown. RAXHA's designed countdown (PRD §4.4, Blueprint A5) would stack a second alarm on a confused elder. For platform-triggered falls RAXHA must coordinate **after/around** the native flow; RAXHA's own countdown applies only to RAXHA-originated triggers. Fall-path sequence diagram is wrong as drawn. → RFC-002.
- **C3 — The charging hole is the anxiety window.** Nightly watch charging = zero coverage during the 3 a.m.-bathroom-fall window families most fear. Pendants last weeks. Surfacing the gap honestly (Coverage Assurance) is not a mitigation for the core promise. → RFC-004 (product decision: daytime-charging routine as default / phone-as-night-sensor fallback / explicit daytime-protection positioning).
- **C4 — D17 veto-contract loophole: suppression-by-degrees.** Context may not *zero* an event but may *lower confidence below threshold* — functionally a veto. Nothing in SRS-403 prevents a "driving" label from dragging a real platform-fall under threshold. → RFC-003 (floor rule: platform-fall + unresponsive ⇒ alert regardless of context-adjusted confidence; VV-102 must test the degraded path, not just the zeroed one).
- **C5 — Beachhead device economics contradict the beachhead.** Most 78-year-olds alone do NOT own Apple Watch + iPhone; the real funnel is the adult child buying a ~$700–1,000 bundle + subscription. Selection effect: elders who already own the hardware skew healthier = lower fall-risk (serving those who need it least). Apple's answer for watch-only elders — **Family Setup** — is excluded by iPhone-required (PDR-002/010) and its third-party capability is unverified. → RFC-005 (re-model funnel as bundle purchase; verify Family Setup feasibility; consider elevating agency/B2B channel to co-primary).

## HIGH
- **H1 — Apple entitlements unfiled SPOFs** (`CMFallDetectionManager`, critical alerts). Months of lead time; denial reshapes the product. → Action A1: file both before Phase 0.
- **H2 — Non-LTE watch + absent phone = detection with no delivery path**; dead-man's switch is blind to incidents that never reached the cloud. → decision inside RFC-004 (require LTE for v1 vs. scope the promise to phone-nearby and say so).
- **H3 — Remote onboarding unengineered** (David in another city; permissions must be granted on Margaret's devices). Most likely funnel killer for this demographic.
- **H4 — Post-acknowledgment dead end.** FSM resolves on `contact_ack`, but **acking ≠ helping**; no outcome-confirmation loop, no re-nudge, no soft follow-up after an embarrassed wearer-cancel (documented pendant behavior). The claimed moat ends one step too early.
- **H5 — Automated voice/SMS deliverability assumed, not engineered.** STIR/SHAKEN robocall filtering, A2P 10DLC registration, "Scam Likely" labeling — the ladder's loudest rung may be silently filtered. → Action A2.
- **H6 — Shadow mode cannot measure sensitivity at v1 scale** (~100 users ⇒ a handful of real falls/year). VV-402/403 exit gates as written may be unpassable in cold start. → add cold-start gate variants with honest confidence intervals.
- **H7 — `DeviceCoverage` lacks a "platform fall detection enabled" field.** Fall detection requires Series 4+, is default-ON only 55+, and can be toggled off — a wearer shows Protected while the primary sensor is dark. Concrete 08B schema gap. → RFC-006 (small).

## MEDIUM
Drill cost/design at 100k users (sampling + synthetic endpoints, unpriced) · responder-without-app web-ack path unspecified · GDPR/EU = written do-not-launch-yet boundary · elder Apple-ID/2FA/updates friction unowned · battery numbers all bench estimates (TD-7) · liability/E&O insurance + ToS/disclaimer architecture absent (needed before beta) · 24/7 human support economics unmodeled.

## MINOR
Trademark search · App Review dossier (health + background location + critical alerts) · wearer-dignity framing ("Protected" can read as surveillance) · elder beta consent design (cognitive decline ethics).

## SURPRISINGLY WELL DESIGNED
Observability asymmetry (manufactured evidence for unobservable hazards) · exactly-once-effect + reboot recovery + dead-man's switch · Boundary (D22) claims-audit as release gate · anomaly-proposes/policy-disposes base-rate discipline · privacy-by-minimization ("nothing sellable exists" is architectural).

## FALSE ASSUMPTIONS (enumerated)
1. Elder already owns the hardware. 2. Always-on on-watch confirmer is runnable. 3. RAXHA owns the fall countdown. 4. Ack ≈ response. 5. Voice calls get through. 6. Shadow validates sensitivity at small scale. 7. Confidence-lowering can't suppress (D17 loophole). 8. Night coverage exists.

## STRONGEST ADVANTAGES
Coverage Assurance as product surface (nobody tells the family whether protection is ON right now) · response-layer depth once H4 fixed · cross-platform + agency/B2B (structurally unattractive to Apple; not Life360's DNA) · the traceability/evidence machine → the regulated, reimbursed elder-care market (Dexcom path).

## BIGGEST UNKNOWNS
Willingness-to-pay vs. free-platform anchor · Family Setup/entitlement outcomes (Apple holds three keys) · real-world FA rate for this demographic · actual elder wear/charge behavior · whether coverage assurance reduces or amplifies family anxiety.

## TOP 10 RISKS BEFORE CODE
1 watchOS spike (C1) · 2 two-countdown redesign (C2) · 3 entitlements unfiled (H1) · 4 beachhead economics/Family Setup (C5) · 5 D17 floor rule (C4) · 6 night/charging decision (C3) · 7 LTE decision (H2) · 8 cold-start V&V variants (H6) · 9 DeviceCoverage schema field (H7) · 10 remote onboarding (H3).

## TOP 10 RISKS BEFORE LAUNCH
1 deliverability/sender registration (H5) · 2 post-ack loop + cancel follow-up (H4) · 3 real-home FA rate vs trust budget · 4 elder non-wear rate · 5 liability/insurance posture · 6 24/7 support economics · 7 drill cost at scale · 8 battery on older watches · 9 Apple deepening family-response (iOS Check In is the warning shot) · 10 elder-dignity/surveillance backlash.
