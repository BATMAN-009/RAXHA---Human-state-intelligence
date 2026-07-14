# Chapter B4 — HealthKit & Health Connect

> **Paired with:** A-1.8 (PPG). That chapter established that physiological data is the strictest privacy tier and that *quality and staleness are safety properties*. This chapter is where that data actually lives on both platforms — and where a subtle truth emerges: **HealthKit and Health Connect are not real-time sensor pipelines; they are consented health *databases*.** Confusing the two is a safety bug. Taught under the Principal Architect contract; carries the three-truths discipline (Doctrine #12) hard, because this is the most platform-truth-heavy chapter yet — every API detail here has a one-OS-release shelf life and must be re-verified before implementation.

---

## 1. Why these frameworks exist

Before them, health data was siloed per app, duplicated, inconsistent, and privacy-hostile. Apple's **HealthKit** (2014) and Google's **Health Connect** (GA 2023, now the Android standard superseding Google Fit's APIs) exist to be a **single, user-controlled, permissioned store** where apps read/write typed health data with per-type consent.

The mental model that prevents the classic mistake: these are **consented databases with schemas and permissions**, optimized for *correctness, provenance, and privacy* — not for low-latency streaming. For RAXHA:
- **Read/write here:** durable health records — resting HR trends, workouts, the fall *events* you log, HRV baselines.
- **Do NOT depend on here for the emergency loop's timing:** real-time HR for an active incident comes from the live sensor path (Core Motion/`HKWorkoutSession` sampling; Wear OS Health Services `MeasureClient`), not from waiting on HealthKit background delivery. HealthKit is the system of record; it is not the wire.

---

## 2. HealthKit internals that matter

- **Typed store:** `HKQuantityType`, `HKCategoryType`, `HKCorrelationType`; every sample carries **provenance** (`HKSource` — which app/device wrote it) and units (enforced — you *must* specify, e.g., `count/min` for HR; unit mismatches throw, which is the framework catching a class of bug for you).
- **Permissions are asymmetric and one-way-opaque:** the user grants read and write *per type*, and — critically — **your app cannot tell whether read access was denied or the data simply doesn't exist** (both look like "no data"). This is a deliberate privacy design and a real engineering constraint: you architect for "absence is ambiguous," never assuming a value's lack means the user has none.
- **Queries:** `HKSampleQuery` (one-shot), **`HKAnchoredObjectQuery`** (incremental — the anchor marks "what I've already seen," the backbone of syncing new samples), `HKStatisticsQuery`/`HKStatisticsCollectionQuery` (aggregates), `HKObserverQuery` + **`enableBackgroundDelivery`** (wake on new data — but at system-scheduled cadence with a frequency ceiling, **not** instant; Doctrine §4 and A-1.8's staleness lesson meet here).
- **watchOS specifics:** `HKWorkoutSession` + `HKLiveWorkoutBuilder` is the sanctioned route to *elevated-frequency* live HR (the armed-mode and active-incident sampling path); `HKHeartbeatSeriesSample` carries beat-to-beat intervals where available.
- **`HKClinicalType`** (health records) and **medical ID** exist — the latter is directly relevant to RAXHA's responder payload (allergies, medications, emergency contacts), though Medical ID access has its own rules.

## 3. Health Connect internals that matter

- **On-device datastore** (an APK component) with a typed schema (`HeartRateRecord`, `OxygenSaturationRecord`, `StepsRecord`, `ExerciseSessionRecord`, ...); apps read/write with **per-record-type, time-bounded, user-revocable** permissions; **Android 14+ integrates Health Connect into Settings** (platform-truth that shifts by release — re-verify).
- **Provenance** via `Metadata`/`DataOrigin` (which app wrote it) — mirror of `HKSource`.
- **Background reads** and change subscriptions exist but, again, are **store-sync mechanisms, not emergency wires**. Live physiological data for an incident comes from **Wear OS Health Services** (`MeasureClient` for on-demand live HR, `PassiveMonitoringClient` for background/passive) — Health Connect is where you persist and share the *record*, not how you race a countdown.
- **Fragmentation reality (B3 recurs):** Health Connect availability, backing OEM health apps, and supported record types vary by device and region — capability-detect, never assume.

## 4. The unifying architecture lesson

Both platforms force the same clean separation, which happens to be exactly the separation RAXHA's doctrine already wants:

```
LIVE SENSOR PATH (low latency, emergency loop)     SYSTEM OF RECORD (durable, consented)
  watchOS: HKWorkoutSession / CoreMotion            HealthKit  (HKAnchoredObjectQuery,
  Wear OS: Health Services MeasureClient              background delivery, provenance)
        │  (seconds, quality-flagged)                Health Connect (typed records, DataOrigin)
        ▼                                                    ▲
   RISK ENGINE (on-device) ──────── writes events/outcomes ─┘
        │   reads durable baselines (resting HR, HRV) ◀──────┘
        ▼
   ESCALATION
```

**The rule:** the risk engine's *timing-critical* inputs come from the live path; its *baseline/context* inputs (what's normal for this user) come from the store; its *outputs* (incident records, detected events) get written to the store as the durable, shareable, provenance-stamped truth. Never invert this — an emergency that waits on `HKObserverQuery` background delivery is an emergency that misses its latency budget.

## 5. Latency, battery, security, failure — the four lenses

- **Latency:** background delivery = seconds-to-minutes, system-scheduled (never the emergency wire); live workout/MeasureClient = seconds, quality-flagged (the wire). A-1.8's staleness rule is enforced here: every value the engine reads carries its timestamp; store-sourced values are assumed stale by default.
- **Battery:** live HR (workout session / MeasureClient) is PPG-continuous = expensive (A-1.8 §4) → used only in armed/active states; passive store sync is cheap. The power-tiering of the *sensor* and the *data path* must agree.
- **Security:** health permissions are the strictest; the store is encrypted at rest by the OS; **the responder payload** (Medical ID: allergies, meds, contacts) is exactly the sensitive data your Direct-Boot/`afterFirstUnlock` analysis (Competency 2–3) said must be handled with the right protection class and *not* placed in the boot-readable journal — it's fetched from the protected store or cloud at send time, after unlock or via authenticated backend.
- **Failure modes:**

| Failure | Cause | Defense |
|---|---|---|
| "User has no baseline HR" | Read denied vs truly absent — indistinguishable | Design for ambiguous absence; degrade gracefully; prompt for permission with a safety rationale |
| Emergency logic waited on background delivery | Treated the store as a live wire | Live path for timing; store for record — architectural separation §4 |
| Stale HR drove a decision | Store value read without checking timestamp | Timestamp/SQI on every value; staleness thresholds |
| Responder payload unavailable at 3 a.m. | Sensitive data in wrong protection class / not synced | Right protection class; cloud-mirrored responder profile; never in boot journal |
| Duplicate/echoed samples | Wrote data another app also wrote; read it back as independent | Use provenance (`HKSource`/`DataOrigin`) to filter your own writes |
| Works, then breaks after OS update | Platform-truth changed | Doctrine #12: re-verify against current docs each release; integration tests on OS betas |

## 6. RAXHA production shape

- **`HealthStoreAdapter` / `HealthConnectAdapter`** behind a shared `HealthRecordStore` protocol/interface (the pure-core rule from B2/B3: the risk engine sees an interface, not `HKHealthStore`).
- **Two clearly-named data paths in code:** `LiveVitalsSource` (workout/MeasureClient, quality-flagged, emergency-loop) vs `HealthRecordStore` (baselines + event persistence). The naming *enforces* the §4 separation so a future engineer can't accidentally wire the countdown to background delivery.
- **Responder profile** (Medical ID-style: contacts, allergies, meds) stored protected + cloud-mirrored, fetched at alert time — never in the Direct-Boot journal.
- **Permission onboarding** as a safety-framed flow (B3 §11 lesson): each health permission asked with a one-sentence why; partial grants map to explicit degraded protection levels.

## 7. Founder Intelligence

**Strategic reading:** HealthKit/Health Connect are the platforms' *health data gravity* — they want to be the store everyone reads/writes, which is leverage over every health app including RAXHA. But the store being commoditized/standardized is *good* for RAXHA: baselines and interoperability come free; the moat was never data storage, it's the *interpretation + response*. **Business-model fork (from A-1.8's investor):** the health store makes PPG-derived insight a plausible subscription (health trends, family health visibility) *distinct from* the safety alarm — RAXHA can be safety (episodic, must-work) + wellness insight (daily engagement) on one data foundation. **Why incumbents leave room:** Apple/Google build the store and basic alerts but not cross-platform family health-safety networks; the store standardization actually *lowers RAXHA's integration cost* while the response/interpretation layer stays open. **Ledger:** ✅ documented APIs, permission models, provenance; 🟡 exact background-delivery scheduling heuristics; 🔴 platform internal fusion feeding the store's HR values. **Kill-relevant:** if RAXHA's value proposition ever reduces to "reads your HealthKit data," Apple can replicate it natively — the interpretation and cross-platform response must be the product.

## 8. Design Review (highlights)

- **Privacy advocate:** "Per-type consent is the floor. Show me the user can grant *fall-safety* without granting *continuous HRV mining*, and that your retention matches your stated purpose."
- **Apple/Google reviewer:** "Requesting broad health read scopes triggers scrutiny and user distrust. Request the minimum; justify each; your privacy label must match your reads exactly."
- **Physician:** "The responder payload — allergies, meds, contacts — is the most valuable 10 seconds of the whole system for the paramedic. Its availability at 3 a.m. on a locked, rebooted phone is a *safety* requirement, not a feature." *(Ties directly to Competency 2–3.)*
- **SRE:** "You said background delivery isn't the wire. Prove there's no code path where an incident's timing depends on it." *(Make it structurally impossible via the two-named-paths design.)*

## 9. Constraint Exercise

Design RAXHA's health-permission onboarding and data architecture for a user who will grant *only* "heart rate" and "fall events" (declining HRV, SpO₂, location-history sync). Constraints: the emergency loop must still hit its latency budget, the responder payload must be available on a locked/rebooted phone, and you must not degrade into reading-the-store-as-a-wire. Specify: which live path vs store each needed value uses, what protection class the responder profile gets, what protection is lost by the declined grants, and the honest degraded-protection message shown to the user.

## 10. Chief Scientist's Verdict

**Confidence Ledger:** "HealthKit/Health Connect are consented stores, not real-time wires" — ★★★★★ (documented architecture; the framing that prevents the core mistake). "Live path (workout/MeasureClient) needed for emergency-loop HR timing" — ★★★★★. "Background delivery cadence is unsuitable for emergency timing" — ★★★★★ (documented). "Provenance filtering prevents self-echo duplicate bugs" — ★★★★☆.
**TRL:** HealthKit — 9. Health Connect — 8–9 (GA 2023, maturing; availability varies — 🟡). Live vitals via workout/MeasureClient — 9. The two-named-paths RAXHA architecture — 7 (standard technique, needs building + a lint/test guard).
**Roadmap:** *MVP:* live path for incident HR; store for resting-HR baseline + fall-event persistence + responder profile. *V2:* HRV baselines, cross-platform family health visibility (subscription surface), AFib-screening record integration. *Research:* richer physiological baselining. *Never Build:* emergency timing dependent on background delivery; broad health-scope requests beyond stated purpose; responder PII in the boot journal.
**Competitor failures (sourced):** the documented history of health apps with privacy-label/permission mismatches drawing App Store enforcement and press — over-requesting health scopes is a trust *and* compliance failure. Google Fit → Health Connect migration friction (documented developer churn) — betting on platform health-data APIs means eating migration cost when the platform re-standardizes; abstract behind your own interface so the migration is one adapter, not a rewrite.
**Kill Criteria:** if minimal-scope onboarding (HR + fall events only) can't deliver a credible safety product, the value prop is over-reliant on invasive data — redesign toward less data, not more consent friction. If any incident-timing code path is found depending on the store rather than the live path in audit, that's a release blocker (correctness, not style).
**Historical Failures (Historian):** Google Fit's long deprecation saga (multiple API generations, developer frustration) — platform health APIs are not stable ground; the adapter pattern is the seatbelt. Samsung/other health platforms that fragmented the Android health-data space pre-Health Connect — the reason Health Connect exists is the failure it replaced; don't re-fragment by inventing your own store.

---

*Competency 5 pairing: A-1.10 (Heart Rate & HRV) + B5 (Core Motion & Android Sensor APIs in production).*
