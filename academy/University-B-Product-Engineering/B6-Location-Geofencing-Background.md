# Chapter B6 — Location Services, Geofencing & Background Execution

> **Paired with:** A-1.6 (GPS/GNSS). The science chapter established that location is the alert *payload*, that its accuracy is a probabilistic field not a fact, and that GPS is power-hungry and event-driven. This chapter is where you *get* location in production on both platforms — under the most-denied permission in mobile, through the background-execution constraints of B2/B3, without draining the battery or lying to the responder. It's also where geofencing becomes a real OS-level primitive rather than a polling loop.

---

## 1. Why this is its own discipline

Location in production is the collision of three things you've already studied: the **most privacy-scrutinized permission** (users are trained to deny background location), the **most power-hungry sensor** (A-1.6 §4), and the **background-execution adversary** (B2/B3). A demo calls `requestLocation()` in the foreground and gets a dot. A safety product must get a *fresh, accuracy-tagged* location *from the background*, possibly *after app termination*, *within seconds of an incident*, *on a permission the user might have granted only "while using,"* *without being killed by Doze or the OEM*, and *without ever leaking or over-retaining* the result. That gap is this chapter.

---

## 2. iOS — Core Location in production

- **Authorization is a ladder, and you climb it deliberately:** `whenInUse` → `always`. iOS 13+ deliberately makes `always` hard — the user may grant "while using," and iOS later shows a "keep allowing background?" prompt with a map of where you've been. You **request `whenInUse` first with a clear safety rationale, then escalate to `always` only when the feature genuinely needs background** (armed monitoring). Over-asking upfront gets you denied.
- **The background-friendly primitives (ranked for a safety app):**
  - **Region monitoring (`CLCircularRegion`) & visit monitoring (`CLVisit`):** OS-level geofencing that **relaunches your terminated app** on enter/exit — very low power, survives app death. The backbone of low-power location awareness.
  - **`startMonitoringSignificantLocationChanges`:** cell/Wi-Fi-based, ~500 m granularity, extremely low power, **relaunches after termination** — the "where roughly is the user" heartbeat.
  - **`allowsBackgroundLocationUpdates` + `location` background mode:** genuine continuous updates — for *active incidents and armed modes only* (battery + review scrutiny).
  - **`CLLocationManager` accuracy tiers:** drop to `HundredMeters`/`Reduced` when you only need context; `Best`/`BestForNavigation` only during an incident.
- **iOS 14+ precise/approximate toggle:** the user can grant *approximate* location — your safety feature must degrade honestly (a coarse location is still a routing hint; say so) and can request temporary precise access with justification.
- **Cold-fix latency:** pre-warm during armed/suspected states (A-1.6 §13) — start updates *before* the alert so a fresh fix is ready when the countdown ends.

## 3. Android — Fused Location & Geofencing in production

- **`FusedLocationProviderClient`:** Play Services' fusion of GPS+Wi-Fi+cell+sensors; request via `Priority.HIGH_ACCURACY` / `BALANCED_POWER_ACCURACY` / `LOW_POWER` / `PASSIVE`. `getCurrentLocation()` (fresh, one-shot) vs `requestLocationUpdates()` (stream) vs `lastLocation` (cached — check staleness!).
- **Permission ladder (stricter each release):** `ACCESS_COARSE` / `ACCESS_FINE`, then **`ACCESS_BACKGROUND_LOCATION`** as a *separate* grant sent to Settings (Android 10+), and Android 12+ lets users grant *only coarse*. Background location triggers **Play Store policy review** — you must justify it in a review form and often a declaration video. For a safety app this is winnable but must be argued (the B2/B3 "entitlement is a business function" lesson).
- **Geofencing API:** OS-level enter/exit/dwell with a `PendingIntent` that wakes your app — low power, but with documented reliability caveats (needs location on, affected by Doze/OEMs, limited geofence count). Treat geofence events as *probabilistic* and debounce.
- **Foreground service of type `location`** (Android 14 typed requirement, B3) for active-incident continuous tracking, with the persistent notification.
- **Fused ≠ magic:** it still can't see indoors accurately, and its "accuracy" is still an estimate — propagate it.

## 4. Geofencing done safely (both platforms)

The magnetometer's hysteresis lesson (Ch 1.3/1.4), now for geographic boundaries:
- **Radius ≥ accuracy:** a 50 m geofence with 40 m location accuracy will flap. Set radius comfortably larger than typical accuracy; ignore crossings reported with poor accuracy.
- **Dwell + debounce:** require the user to be inside/outside for a minimum time before firing — kills jitter-induced false crossings.
- **Hysteresis:** different effective thresholds for enter vs exit.
- **RAXHA uses:** home/safe-zone awareness (elder wandering, child safety — the "walking-alone" and dementia-elopement features), and *context* for escalation (at home vs unfamiliar location changes the alert). Never make a *life-critical* trigger depend solely on a single geofence crossing — corroborate (Decision #11/#13).

## 5. Latency, battery, security, failure — the four lenses

- **Latency:** significant-change/region = seconds-to-minutes wake, cheap; one-shot high-accuracy = seconds but must be *pre-warmed* for incidents; cached last-known = instant but possibly stale (must check age). Match the tier to the need.
- **Battery:** accuracy tier + duty cycle are the dials (A-1.6). Baseline low-power awareness; high-accuracy only in armed/active states, gated by the risk engine. Per-mode measured-mW table is a ship requirement.
- **Security/privacy (the heaviest lens for location):**
  - **Retention:** location stored server-side *only for the active incident*, short TTL, then purged. Baseline location stays on-device.
  - **Sharing:** responder/family location via **short-lived, token-scoped, revocable** links that **expire when the incident closes** — never a permanent URL, never location in a query string (system doctrine).
  - **Non-monetization is architectural:** design the schema so there is no location history to sell (the Life360 anti-pattern made structurally impossible, not just policy-forbidden).
  - **Minimization:** request the coarsest accuracy and shortest retention that still saves the life.
- **Failure modes:**

| Failure | Cause | Defense |
|---|---|---|
| Background location denied | Most-denied permission | Staged rationale-first request; degrade to foreground/at-home-only with honest coverage messaging |
| Stale cached location in alert | `lastLocation`/last-known used without age check | Staleness field + threshold; pre-warm fresh fix during armed state |
| Late fix delays the alert | Cold start post-countdown | Pre-warm on suspected-incident; send last-known immediately, update when fresh fix lands |
| Geofence flapping / missed | GPS jitter, Doze, OEM | Radius≥accuracy, dwell, hysteresis; treat as probabilistic; corroborate |
| Killed before it can send location | OEM/Doze (B3) | Significant-change relaunch, high-priority FCM, cloud dead-man's switch |
| Location leaked/over-retained | URL params, long TTL, broad sharing | Token-scoped expiring shares; incident-only server retention; no query-string location |
| Approximate-only grant treated as precise | iOS/Android coarse grant | Detect precision level; degrade honestly; show uncertainty |

## 6. RAXHA production shape

- **`LocationProvider` interface** in the pure core (B2/B3 rule); `AppleLocationAdapter` (Core Location) and `AndroidLocationAdapter` (Fused) implement it, emitting the accuracy+timestamp-tagged `Location` into the same `Sample`-style contract as B5.
- **Two named tiers in code:** `AmbientLocationSource` (significant-change/region, low power, always-ish) vs `IncidentLocationSource` (high-accuracy, pre-warmed, incident-scoped) — naming enforces the power/latency separation so nobody leaves high-accuracy on.
- **`SafeZoneManager`** wraps OS geofencing with RAXHA's radius/dwell/hysteresis policy and corroboration rules.
- **`LocationShareService`** (cloud): mints expiring, revocable, token-scoped share links; enforces incident-only retention and purge-on-close; no location in URLs.
- **Registered home/safe addresses** as the indoor fallback (A-1.6 §13) — when GPS is unusable at home, the known address is the honest best answer.

## 7. Founder Intelligence

**Strategic reading:** location is simultaneously RAXHA's most valuable feature (makes detection actionable; the family-safety wedge) and its most dangerous asset (the thing that destroyed a competitor's trust). The winning posture post-Life360 is **provable non-monetization as a primary differentiator** — but it only works if it's architectural (no history to sell) rather than promissory. **Why incumbents leave room:** Apple/Google own location tech but not cross-platform family-safety with a *credible privacy stance*; Life360 owns the family graph but carries the data-broker scar. RAXHA's wedge is the trustworthy version. **Platform reality:** background location is a permission *and* a Play/App-Review gate *and* a battery cost — three taxes competitors pay too; the moat is paying them well (great onboarding conversion, honest battery, provable privacy). **Ledger:** ✅ documented APIs, permission models, geofencing behavior; 🟡 fused-provider internals, geofence reliability specifics per OEM; 🔴 platform location-inference internals. **Kill-relevant:** if background-location onboarding conversion is too low to sustain coverage, the consumer motion needs rethinking (guided B2B/elder-care deployment where staff configure permissions — echoing B3's kill criterion).

## 8. Design Review (highlights)

- **Privacy advocate:** "Show me there is no location history to subpoena or sell. Incident-only retention, expiring shares, no query-string location — in the schema, not the privacy policy."
- **Apple/Google reviewer:** "Background `always`/`ACCESS_BACKGROUND_LOCATION` needs a justification users and reviewers will read. Your safety case is legitimate; request it staged, rationale-first, minimal accuracy."
- **Emergency physician:** "The commonest fall is at home, where GPS fails. Your registered-address fallback and indoor plan (Ch 1.7) are the *actual* location story for my patients — don't bury them behind the outdoor happy path."
- **SRE:** "When the app is killed before it sends location, what fires? Prove the cloud dead-man's switch escalates without the phone's fresh fix."

## 9. Constraint Exercise

Design RAXHA's location onboarding + runtime for a privacy-anxious user who grants only "while using" + approximate location, on a phone with an aggressive OEM battery manager. Constraints: alerts must still carry a *usable* location, the home-fall case must work, battery budget is tight, and location must never be retained beyond the incident. Specify: the permission-escalation UX and its rationale copy, what protection level exists at "while-using + approximate," the pre-warm and fallback strategy, the geofence policy, and the exact retention/sharing design — plus the honest coverage message the user sees.

## 10. Chief Scientist's Verdict

**Confidence Ledger:** "Region/significant-change relaunch the app at low power" — ★★★★★ (documented). "Background location is the most-denied permission" — ★★★★☆ (well-supported by developer data). "Fused/OS accuracy is an estimate to propagate, not a bound to trust" — ★★★★★. "OS geofencing is reliable enough for life-critical *sole* triggers" — ★★☆☆☆ (**it is not — corroborate; documented reliability caveats**). "Expiring token-scoped sharing prevents the Life360 failure" — ★★★★☆ (sound if architecturally enforced).
**TRL:** Core Location / Fused Location in production — 9. OS geofencing — 8–9 (reliable with dwell/hysteresis; caveats). Pre-warm + tiered power location — 8. Provable non-monetization architecture — 7 (standard techniques; needs deliberate schema design + audit). Home-indoor fallback via registered address — 8.
**Roadmap:** *MVP:* tiered location (ambient + incident), staged permissions, expiring shares, incident-only retention, registered-address indoor fallback. *V2:* refined geofencing safe-zones (wandering/child), approximate-grant graceful degradation, satellite/off-grid path. *Research:* seamless indoor-outdoor, on-device uncertainty. *Never Build:* life-critical sole-geofence triggers; location in URLs; any server-side location beyond the incident; monetized/broker-able location.
**Competitor failures (sourced):** Life360 data-broker sale (the architectural lesson: make it impossible). Documented cases of apps caught retaining/selling background location (FTC actions, press) — the regulatory-and-trust cost of getting retention wrong. Geofencing-reliability complaints across consumer apps (missed/delayed enter-exit, widely reported) — why RAXHA never makes a life-critical decision on one crossing.
**Kill Criteria:** if background-location conversion can't sustain coverage after onboarding iteration, pivot to guided/B2B deployment. If non-monetization can't be made architecturally provable and auditable, don't market privacy as a differentiator. If home-case location can't be made actionable, scope claims honestly and lean on registered addresses + Ch 1.7.
**Historical Failures (Historian):** Life360 (again — the canonical case). Foursquare/early location-social apps that over-collected and lost user trust. The broader "background location scandal" genre (multiple apps exposed for covert location sale) — location is the asset most likely to turn a safety brand into a privacy villain; architecture, not policy, is the only real defense.

---

## 11. Knowledge Graph Connections

- **Depends on (prior):** A-1.6 (GPS science); B2/B3 (background execution — location is a background problem); Decision #11 (cloud dead-man's switch when the phone can't send location).
- **Depended on by (future):** B7 (BLE ranging as indoor-location + watch↔phone transport); every alert that carries a location; the Escalation/Response subsystem.
- **RAXHA subsystem:** acquisition (`AmbientLocationSource`/`IncidentLocationSource`), `SafeZoneManager` (geofencing), `LocationShareService` (expiring-token sharing).
- **AI models consuming it:** none directly (location is context/payload) — but feeds the Context Engine and Risk Scoring.
- **Sensors contributing:** GNSS + Wi-Fi + cell + IMU (via Fused/Core Location).
- **Assumptions for validity:** background-location permission granted (most-denied); accuracy propagated; retention is incident-only; sharing tokens expire. Break any → degraded/coverage-gap state, surfaced honestly.
- **Confidence:** infrastructure ★★★★★; provable non-monetization ★★★★ (needs architectural enforcement). See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Competency 7 pairing: A-1.7 (Wi-Fi / BLE / UWB positioning, dead reckoning, indoor positioning) + B7 (Bluetooth LE & watch↔phone communication) — the indoor-location answer the physician keeps demanding.*
