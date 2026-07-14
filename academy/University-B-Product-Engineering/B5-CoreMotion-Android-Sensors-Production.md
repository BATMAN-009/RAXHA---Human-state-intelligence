# Chapter B5 — Core Motion & Android Sensor APIs in Production

> **Paired with:** A-1.10 (HR & HRV). The science track just taught that a value is worthless without its metadata (metric type, window, condition, quality, timestamp). This chapter is where that lesson becomes *code*: how you actually acquire sensor data in production on both platforms, batch it, timestamp it, survive process death, and hand the risk engine values it can trust. Everything in B2/B3 about background execution was the *stage*; this is the *acquisition layer* that runs on it. Heavy platform-truth (Doctrine #12): re-verify against current docs before implementation.

---

## 1. Why a production sensor layer is its own discipline

A demo reads `didUpdate` callbacks and plots them. A safety product must answer, for every sample: *when exactly was this measured (not received)? is it in order? did we drop any? what's its quality? did the buffer overflow while we slept? is this value stale enough to be dangerous?* The gap between those two is this chapter. The naive path produces a fall detector that works on your desk and misses falls at 3 a.m. under Doze — the exact failure the whole curriculum exists to prevent.

---

## 2. iOS/watchOS — Core Motion in production

- **`CMMotionManager`:** the raw-sensor entry point. Set `accelerometerUpdateInterval` / `gyroUpdateInterval` (up to ~100 Hz typical); prefer **`startDeviceMotionUpdates`** for *fused* output (`CMDeviceMotion`: `userAcceleration` and `gravity` pre-separated, `attitude`, `rotationRate` bias-corrected) — Apple's fusion is better than hand-rolling from raw, and it's free.
- **Timestamps are the critical detail:** `CMLogItem.timestamp` is **seconds since device boot** (mach uptime domain), *not* wall-clock — monotonic (survives NTP adjustments, good) but resets on reboot and must be converted to a stable timeline for cross-sensor fusion and cloud correlation. Getting this wrong desynchronizes accel from PPG and corrupts every fused feature. Convert once, at ingestion, to a documented reference.
- **`CMSensorRecorder`:** records **accelerometer only** at 50 Hz into a system buffer for *retrospective* retrieval (up to ~12 h back) even when your app wasn't running — the watchOS way to get pre-event data without staying alive. No gyro, no PPG (recall A-1.2 §6). It's a forensic buffer, not a live stream.
- **`CMBatchedSensorManager`** (newer watchOS): higher-rate batched accelerometer+gyro delivery designed for efficiency — verify availability/behavior on your target watchOS (platform truth).
- **Live vitals path:** `HKWorkoutSession` + `HKLiveWorkoutBuilder` for elevated-rate HR (the A-1.8/B4 live path). Core Motion for kinematics, HealthKit-live for physiology — two acquisition subsystems, one timeline.
- **Delivery target:** an `OperationQueue` (background, never main — the `0x8badf00d` rule from B2). Push samples into a lock-free-ish ring buffer consumed by the risk engine actor.

## 3. Android/Wear OS — SensorManager & Health Services in production

- **`SensorManager.registerListener`** with a sampling period *and* **`maxReportLatencyUs`** — the batching parameter that lets the **sensor hub FIFO** buffer samples while the AP sleeps (the single most important battery API on Android; B1 §3). Large latency = deep batching = AP sleeps longer = big power win, at the cost of delivery delay (fine for logging, not for the live incident path — use small/zero latency there).
- **Timestamps:** `SensorEvent.timestamp` is **nanoseconds, but its base is device-dependent** — historically some OEMs used boot-time, others epoch, a notorious fragmentation bug. You must **detect and normalize** the clock base per device (measure offset against `SystemClock.elapsedRealtimeNanos()`), or cross-sensor fusion silently corrupts on certain phones. This is the Android twin of the Core Motion timestamp lesson, and worse.
- **Wake-up vs non-wake-up sensors:** non-wake-up sensors let the SoC sleep and may drop/batch; **wake-up** variants guarantee delivery — safety-critical triggers need wake-up sensors or hub-offloaded detection (Health Services). Sampling >200 Hz needs `HIGH_SAMPLING_RATE_SENSORS` permission (the side-channel gate from A-1.1 §11).
- **Health Services (Wear OS):** `MeasureClient` (on-demand live HR, for incidents/armed modes), `PassiveMonitoringClient` (background passive data + events, low-power), and platform detectors where available. This is the *offloaded* acquisition path — detection/monitoring on the low-power MCU, delivering events not raw streams. Prefer it for battery; accept its granularity.
- **Delivery target:** a bound/foreground service (B3) feeding a coroutine `Flow` into Room-backed buffering + the risk engine.

## 4. The cross-platform acquisition contract (what the risk engine demands)

Both platforms must hand `RiskEngineCore` the same shape, so the pure core (B2/B3) never sees an OS type:

```
Sample {
  monotonicTimestampNs   // normalized to ONE documented timeline
  values[]               // accel xyz / gyro xyz / hr bpm / ...
  quality / SQI          // A-1.8/1.10: quality is a first-class field
  source / provenance     // which sensor/device
  seqOrGapMarker         // detect drops & reordering
}
```
Rules encoded here: **measured-time not received-time; monotonic normalized clock; quality attached at the source; gaps explicit, never silently interpolated; staleness computable by the consumer** (Decision #13 — "I don't know" is a representable state). The adapters (`SensorAdapters` in B2/B3's tree) do all OS-specific messiness; the contract is platform-agnostic and testable with recorded traces.

## 5. Latency, battery, failure

- **Latency:** live incident path = small/zero batching, wake-up sensors, `MeasureClient` — seconds. Background monitoring = deep batching, passive clients — minutes, cheap. The two paths coexist and must be distinct in code (echo of B4's two-named-paths rule).
- **Battery:** batching depth is the master dial on Android; duty-cycling (accel-gates-gyro-gates-PPG) is the master dial for which sensors run (A-1.2/1.8). Per-sensor power telemetry + CI assertions on duty cycle prevent regressions where "someone left the gyro/PPG on."
- **Failure modes:**

| Failure | Cause | Defense |
|---|---|---|
| Accel/PPG desynchronized in fusion | Mixed clock domains / unnormalized timestamps | Normalize to one timeline at ingestion; validate offset per device |
| Silent sample drops under load/Doze | Non-wake-up sensor, FIFO overflow while asleep | Wake-up sensors on critical path; gap markers; overflow detection |
| "Fresh" value was 40 s old | Event-driven HR treated as continuous | Staleness field + thresholds in the engine (A-1.8) |
| Works on Pixel, corrupts on brand X | OEM timestamp-base divergence | Per-device clock-base detection (§3) |
| Main thread janks / watchdog kill | Sensor processing on main | Background queue/coroutine; never main (B2) |
| Pre-event window missing | Didn't buffer before trigger | Ring buffer (accel) / `CMSensorRecorder`; buffer is always-on even when detection is idle |

## 6. RAXHA production shape

The `SensorAdapters` layer from B2/B3, specified:
- **`AppleMotionAdapter`** (Core Motion + `CMSensorRecorder` + batched manager) and **`AppleVitalsAdapter`** (HK live) → the `Sample` contract.
- **`AndroidSensorAdapter`** (SensorManager, per-device clock normalization) and **`WearHealthServicesAdapter`** (Measure/Passive) → same contract.
- **Shared `RingBuffer` + `GapDetector` + `StalenessPolicy`** in pure core — one implementation, both platforms, one test corpus of recorded traces (including deliberately corrupted/dropped/out-of-order traces to prove the defenses fire).
- **Golden test:** replay a recorded fall+reboot+Doze trace through the adapter→contract→engine and assert correct outcome and correct staleness/gap handling — the acquisition-layer version of the replay CI promised since B1.

## 7. Founder Intelligence

**Strategic reading:** the acquisition layer is unglamorous and is exactly where safety products are quietly won or lost — the timestamp-normalization and gap-handling work has no demo value and enormous reliability value, which is why feature-driven competitors skimp on it and why it's a real moat for a team that treats reliability as the product. **Why incumbents are ahead here:** Apple/Google spent a decade on fused, well-timestamped sensor pipelines — on *their* hardware; RAXHA's edge isn't out-engineering their fusion (don't) but *composing* their outputs correctly across both platforms with honest quality/staleness accounting. **Ledger:** ✅ documented APIs, timestamp domains, batching; 🟡 exact OEM timestamp-base quirks (empirical, per-device — telemetry over docs); 🔴 platform fusion internals. **Kill-relevant:** if the acquisition layer can't deliver clean, correctly-timed, quality-tagged samples across the top OEMs, no downstream ML matters — this layer is a *prerequisite*, and its failure is a reason to narrow device support, not to paper over with model hacks.

## 8. Design Review (highlights)

- **Chief Scientist:** "Show me the clock-normalization validation across devices. Every fused feature I trust depends on it, and I don't believe it works until I see the per-OEM offset tests."
- **SRE:** "Where's the gap/drop telemetry? If a sensor stream silently thins out at night, coverage telemetry must catch it — a quiet acquisition failure is invisible non-protection."
- **Security researcher:** ">200 Hz needs the high-rate permission and opens side-channels (A-1.1/1.2). Do you actually need it, and if so, justify and contain it."
- **Battery reviewer (Garmin-style):** "Your batching depth and duty cycle per mode, in a table, with measured mAh. No number, no ship."

## 9. Constraint Exercise

Design the acquisition layer for the fall path across iOS and Android with: a required 10 s pre-event + 20 s post-event buffer, correct cross-sensor timing for accel+gyro fusion, survival of a mid-event reboot, and a battery budget that forbids continuous gyro/PPG. Specify per platform: which APIs, batching latencies, wake-up vs non-wake-up choices, clock normalization method, the buffer design, and the three golden replay traces you'd put in CI to prove it works.

## 10. Chief Scientist's Verdict

**Confidence Ledger:** "Measured-time, monotonic-normalized timestamps are required for valid fusion" — ★★★★★. "Android SensorEvent timestamp base is device-fragmented and must be normalized" — ★★★★☆ (well-documented historically; per-device specifics 🟡). "Batching/FIFO is the master battery dial on Android" — ★★★★★. "`CMSensorRecorder` gives retrospective accel-only buffer" — ★★★★★ (documented). "Fused Core Motion output beats hand-rolled from raw" — ★★★★☆.
**TRL:** Core Motion / SensorManager / Health Services acquisition — 9. The normalized cross-platform `Sample` contract — 8 (standard engineering, needs building). Per-OEM clock normalization at fleet scale — 6–7 (known technique; the long tail of devices is the risk). Golden-trace replay CI for acquisition — 7.
**Roadmap:** *MVP:* accel ring buffer + live-HR path + normalized timestamps + gap/staleness on top OEMs and Apple Watch. *V2:* `CMSensorRecorder`/batched managers, broader OEM clock-normalization coverage, per-sensor power telemetry. *Research:* adaptive-rate acquisition. *Never Build:* fusion on unnormalized timestamps; treating received-time as measured-time; silent interpolation over gaps.
**Competitor failures (sourced):** the documented Android sensor-timestamp fragmentation saga (developer reports, platform bug history) — teams that assumed a uniform clock shipped silently-wrong fusion on subsets of devices; the lesson is empirical per-device validation, not trust in the spec. Fitness apps with GPS/sensor time-sync bugs producing impossible speeds/distances (widely reported) — timing errors surface as absurd outputs that destroy user trust instantly.
**Kill Criteria:** if clock normalization can't be validated to acceptable error on a target OEM, drop that OEM from the supported list rather than ship corrupt fusion (narrow honestly). If acquisition gap-rate on a device class exceeds a threshold in telemetry, that device is "degraded protection," surfaced to the user (Decision #13/#14), not silently supported.
**Historical Failures (Historian):** early Android Wear sensor-API instability (B3's ledger) — building on shifting acquisition primitives cost developers years; anchor on the primitives the platform owners depend on. The broader wearable-industry pattern of impressive demos that failed in daily life — almost always an acquisition/reliability gap (drops, staleness, mis-timing) hidden beneath a good-looking algorithm; the unglamorous layer is where trust is actually built.

---

*Competency 6 pairing: A-1.6 (GPS/GNSS) + B6 (Location services, geofencing & background execution).*
