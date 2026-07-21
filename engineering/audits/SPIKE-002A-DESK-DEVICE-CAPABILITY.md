# SPIKE-002A — Desk Addendum: Device Capability & Family Setup Documentation Sweep

> **Date:** 2026-07-21 · **Executor:** Claude (pair architect), under founder instruction to gather internet-sourced device data for SPIKE-002.
> **Class of evidence: DOCUMENTATION-LEVEL.** This addendum records what Apple and the developer community *document*. It does **not** replace SPIKE-002's hardware run. Per the Evidence Register rule, no row is upgraded to ✅ by argument — the third-party-API-on-managed-watch question (E-07) remains answerable **only by hardware**.

## What this addendum establishes

| # | Finding | Source class | Confidence |
|---|---|---|---|
| D1 | **Family Setup requires a cellular watch** — Apple Watch Series 4 or later, or any Apple Watch SE, with cellular; watchOS 7+; set up from an organizer iPhone (iOS 14+). GPS-only watches cannot be family-set-up. | Apple Support ([109036](https://support.apple.com/en-us/109036)) | ✅ documented |
| D2 | **Native fall detection IS available on a family-managed watch** (wearer 18+; auto-enabled at 55+). Emergency calling from the managed watch requires its own number/cell service (or Wi-Fi calling). Apple's own SOS flow runs on the managed watch. | Apple Support ([108896](https://support.apple.com/en-us/108896), [manage fall detection](https://support.apple.com/guide/watch/apd34c409704/watchos)); Apple Community ([thread 255026216](https://discussions.apple.com/thread/255026216), [255058553](https://discussions.apple.com/thread/255058553)) | ✅ documented |
| D3 | **2026 lineup (all cellular-capable, all 5G):** Series 11 (~$399, 5G), SE 3 (~$249 base, cellular option, **2× fast charging**, full safety suite: fall detection, crash detection, Emergency SOS, Check In), Ultra 3 (cellular standard, **42 h rated battery**). Fall detection spans **Series 4+ including every SE and Ultra**, GPS and cellular units alike. | Apple Newsroom ([SE 3](https://www.apple.com/newsroom/2025/09/apple-introduces-apple-watch-se-3/)); announcement coverage ([Series 11/Ultra 3](https://finance.yahoo.com/news/apple-reveals-apple-watch-series-11-and-ultra-3-with-hypertension-detection-improved-durability-174053517.html)); capability guides | ✅ documented (pricing/ratings vendor-stated) |
| D4 | Third-party fall API (`CMFallDetectionManager`, entitlement `com.apple.developer.health.fall-detection`, `didDetect` with resolution + background time) is documented for watchOS apps generally; entitlement grant ~2–3 days per community reports. **No documentation or community evidence exists — in either direction — on whether the entitlement/API functions on a Family Setup managed watch.** | Apple Developer ([CMFallDetectionManager](https://developer.apple.com/documentation/coremotion/cmfalldetectionmanager), [forums 685761](https://developer.apple.com/forums/thread/685761), [680898](https://developer.apple.com/forums/thread/680898)) | 🔴 **gap confirmed as a gap** |
| D5 | Apps are installable directly on a managed watch via the watch's own App Store; apps that *require* a companion iPhone are unavailable there. (An independent watch app — RAXHA's shape under RFC-005 — is the installable kind.) | Apple Support / community ([app install thread](https://discussions.apple.com/thread/253504496)) | 🟡 documented, not exercised |

## What this addendum deliberately does NOT establish

- **E-07's core question** — does `didDetect` + resolution reach a *third-party* app on a managed watch — is **not answered**. Native fall detection working there (D2) is necessary-but-not-sufficient: RAXHA's v1 engine (RFC-001/002) consumes the *API event*, not the native UI. **SPIKE-002 hardware run remains mandatory before RFC-005 finalizes.**
- E-08 (HealthKit real-time reads without iPhone) — still mixed reports; hardware sub-test stands.
- Battery under RAXHA's workload (E-14) — Ultra 3's 42 h rating and SE 3's 2× fast charge are *product-relevant inputs to RFC-004* (fast charging shrinks the daily charging hole; 42 h can span night-wear + daytime-charge routine) but are marketing ratings, not SPIKE-003 profiles.

## Procurement list (updated to 2026 lineup — founder purchase, A-item)

1. **Apple Watch SE 3, cellular** (~$299) — the price-floor device *and* the fast-charging data point for RFC-004; full safety suite confirmed.
2. **Apple Watch Series 11, cellular** (~$499) — primary test device, current mainstream.
3. **Used Series 4/5/SE (1st gen), cellular** — old-hardware floor (fall detection floor is Series 4).
4. *(Optional, RFC-004 exploration)* **Ultra 3** — 42 h battery reshapes the night-coverage question; defer unless RFC-004 leans on overnight wear.
5. Test iPhone (iOS current), eSIM/plan for the watch, second phone for responder side.

Prereq unchanged: **A1 entitlement filing precedes the spike** (fall-detection entitlement on the test app).

## Register impact (applied 2026-07-21)

- E-06 strengthened (native-fall-on-managed-watch now sourced; app installability noted) — stays 🟡 pending hardware.
- E-07 clarified: native leg ✅ documented / **third-party leg stays 🔴** — the spike's pass/fail criterion is unchanged.
- E-14 annotated with D5 documentation-level inputs; stays 🔴.
