# SPIKE-001 — watchOS Platform-Truth Verification (2026-07-14)

> Live re-verification of the platform assumptions gating RFC-001/002/004/005 (Doctrine D12: platform truth is re-verified against current documentation, never assumed). Sources: Apple Developer documentation/forums + practitioner reports, July 2026. Labels: ✅ documented · 🟡 community-reported/needs-device-confirmation · 🔴 unverified, requires physical hardware test.

## Findings

**F1 — `CMFallDetectionManager` (the platform fall event):**
- ✅ Entitlement: `com.apple.developer.health.fall-detection`, applied for via Apple's request process. 🟡 Community-reported turnaround **~2–3 days** (far shorter than feared — but approval remains discretionary).
- ✅ **Behavior on fall: Apple's Standard UI opens first (SOS / acknowledge options); third-party apps then receive background time and the `didDetect` event with the resolution.**
- **Implication:** RFC-002 is *confirmed by documentation* — Apple owns the moment of the fall; RAXHA is architecturally an *after-the-native-flow coordinator* for platform-triggered falls. Conveniently, the API delivers exactly what the re-scoped v1 engine needs: the event **plus its resolution** (user responded / SOS called / unresponsive).

**F2 — `CMSensorRecorder` (retrospective accelerometer):**
- ✅ 50 Hz accelerometer, batch/retrospective retrieval only. 🟡 Practitioner reports: retrieval of long recordings is unreliable/crash-prone; no live-stream use.
- **Implication:** not a viable live-confirmer path. Confirms RFC-001's direction (C1).

**F3 — `CMBatchedSensorManager` (high-rate sensing):**
- ✅ 800 Hz accelerometer / 200 Hz device-motion — **but requires an active HealthKit workout session**, and high-rate support is **Series 8/Ultra-class hardware**.
- **Implication:** RAXHA's *own* high-rate sensing is feasible **only in armed modes** (workout-session-backed) — exactly RFC-001's carve-out. Adds a hardware-matrix note: fall detection needs Series 4+; own high-rate sensing needs Series 8+.

**F4 — Family Setup (managed watch, no elder iPhone):**
- ✅ Requires a **cellular (LTE) Apple Watch, Series 4+**. Managed watches have no companion iPhone; **third-party apps that require an iPhone won't work — but independent watch apps can be installed from the watch App Store.**
- 🔴 **Unverified: whether the fall-detection entitlement/API functions on a Family Setup managed watch.** This is the single remaining hardware-lab question, and it decides RFC-005.
- **Implication — a genuine convergence:** Family Setup *forces* LTE, which collapses RFC-004's LTE question and RFC-005's no-iPhone-elder segment into one coherent alternative product shape: **independent watch-only wearer app + caregiver's phone/cloud as Tier-2.** If F4-🔴 verifies, this may be a *better* v1 than iPhone-paired — it solves H2 (no-phone delivery), serves the true beachhead, and simplifies the elder's side to one device.

**F5 — Independent watchOS apps:**
- ✅ Fully supported (no companion iOS app needed); CoreMotion + HealthKit usable. 🟡 Some HealthKit real-time flows degrade without an iPhone present — our specific reads need targeted testing.

**F6 — Critical alerts entitlement:**
- ✅ Requested via Apple's dedicated form; hand-vetted, **days-to-weeks**, resubmission common. ✅ **Approved use cases explicitly include personal-safety/SOS and patient-monitoring** — RAXHA's responder-side case is squarely inside the approved category.
- **Implication:** A1 stays urgent (file both entitlements now) but the odds are favorable and the lead time is weeks, not months — H1's severity downgrades from Critical-adjacent to manageable-if-filed-early.

## What this settles vs. what still needs a device lab
- **Settled by documentation:** the two-countdown reality (RFC-002 ✅ confirmed), the infeasibility of always-on own-sensing outside workout sessions (RFC-001 ✅ confirmed in direction), armed-mode high-rate feasibility + hardware floors, Family Setup's LTE requirement, critical-alerts fit.
- **Requires physical hardware (the residual spike, ~1 week with devices):** fall-detection API behavior on a Family Setup watch (🔴, decides RFC-005); real `didDetect` delivery latency; `CMSensorRecorder` reliability on current watchOS; HealthKit reads on independent apps without iPhone; battery reality of an armed-mode workout session.

## Recommendation to the founder (decision remains yours)
Accept **RFC-001** and **RFC-002** — the platform documentation, not just my audit, now mandates them. Fold the **Family Setup verification** into a 1-week hardware spike as the first Phase-0 activity (it can run alongside pure-core work), because its outcome decides RFC-004/005 — and possibly improves the entire v1 shape.
