# Chapter B7 — Bluetooth LE & Watch↔Phone Communication

> **Paired with:** A-1.7 (indoor positioning). That chapter used BLE as a *positioning* signal; this one uses it as the *nervous system* connecting RAXHA's tiers — the watch↔phone link that the entire four-tier architecture (B1) silently assumed works. It usually doesn't work as well as you'd hope, and a safety product must be engineered for the link being down ~10% of the time. This is where the "tier autonomy invariant" (Decision #4) stops being a slogan and becomes wire-level protocol design.

---

## 1. Why BLE exists and why it's the watch↔phone link

Classic Bluetooth (BR/EDR) was built for streaming (audio) — power-hungry, connection-heavy. **Bluetooth Low Energy** (BLE, from Bluetooth 4.0, 2010) was a near-separate protocol designed for *tiny, infrequent data at microwatt-average power* — sensors, beacons, wearables. A coin cell runs a BLE sensor for a year. That power profile is why every smartwatch talks to its phone primarily over BLE, and why RAXHA's data-plane rule (raw stays on watch, only events/features cross — B1 §5) is partly a *BLE bandwidth* rule: BLE gives you comfortable KB/s, not MB/s. You physically cannot stream raw waveforms over it, which is a feature (it forces the right architecture).

---

## 2. BLE internals that matter

- **GATT (Generic Attribute Profile):** the data model — a **server** (peripheral) exposes **services** containing **characteristics** (values) that a **client** (central) reads, writes, or subscribes to (**notify/indicate**). RAXHA's watch↔phone messages map onto characteristics; **indications** (acknowledged) vs **notifications** (unacknowledged) is your first reliability decision — safety-critical messages want acknowledged delivery.
- **Advertising vs connection:** peripherals *advertise* (broadcast, connectionless — this is also how beacons/positioning work, tying to A-1.7); centrals *scan* and then *connect*. Connection parameters (interval, latency, timeout) trade power vs latency — a long connection interval saves battery but delays messages, a real latency line-item for an emergency.
- **MTU & throughput:** small default packet size (negotiable up); throughput is modest and degrades with distance/interference. Design messages as compact, self-contained event/feature records — never streams (echoes the B5 `Sample` contract discipline).
- **Range & reliability:** ~10 m indoors through bodies/walls, worse in practice. The link drops when the phone is in another room, in a bag, or the watch is charging. **Assume frequent, normal disconnection.**

---

## 3. The platform layers above raw BLE

RAXHA rarely uses raw GATT for its own watch↔phone traffic — the platforms provide higher-level, more reliable transports:

- **Apple — WatchConnectivity (`WCSession`):** the sanctioned Apple Watch↔iPhone channel. Its *modes* are a lesson in delivery semantics you must choose correctly:
  - `sendMessage` — live, both apps foreground/reachable, low latency (incident-time).
  - `transferUserInfo` — **queued, guaranteed, FIFO** delivery even if the peer is unreachable now (survives disconnection — the safety default for events).
  - `updateApplicationContext` — latest-state-wins (good for "current status," not for event logs where every one matters).
  - `transferFile` — bulk.
  - **The design rule:** incident events use the *guaranteed queued* path (`transferUserInfo`) so a disconnected phone still receives them on reconnect; only the live countdown UI uses `sendMessage`. This is the store-and-forward the architecture demanded (B1 §5), handed to you by the OS.
- **Android/Wear OS — Data Layer API:** `MessageClient` (live messages), **`DataClient`** (`DataItem`s that **sync automatically with offline buffering** — the guaranteed path), `CapabilityClient` (discover what the peer can do), `ChannelClient` (streams). Same pattern: `DataClient` for events that must survive disconnection, `MessageClient` for live.
- **Both** run over BLE (and Wi-Fi/cloud relay when available) but abstract the reconnection/buffering — *use them instead of raw GATT for RAXHA's own traffic*; use raw BLE only for third-party sensors/beacons.

---

## 4. The tier-autonomy invariant becomes protocol

Decision #4 said every tier must be useful when the tier above is unreachable. BLE is where that gets designed:

- **Watch assumes the phone is absent** ~10% of the time (another room) and sometimes always (left at home). So the watch must: buffer events locally (durable, B2/B3), keep a local alarm/UI, and — if LTE-capable — be able to escalate *directly* (Decision #2 amendment) without the phone.
- **Phone assumes the watch may disconnect** mid-incident: it holds the last known state, and the cloud dead-man's switch (Decision #11) covers the case where *both* the link and the phone's own connectivity fail.
- **The link itself is monitored:** a watch↔phone heartbeat; a missing heartbeat is a *coverage-degradation signal* (surface it, Decision #14), not silence.
- **Idempotency across the link:** events carry IDs; a message redelivered after a flaky reconnection must not double-trigger (the same idempotency you designed for reboot recovery in Competency 2, now for link flakiness).

---

## 5. Latency, battery, security, failure

- **Latency:** `sendMessage`/`MessageClient` = sub-second when connected; guaranteed-queued paths = whenever reconnection happens (could be minutes). Route incident-critical timing through live paths *with* the queued path as backstop, and never let the countdown depend solely on the link (watch-local countdown + phone mirror).
- **Battery:** connection interval is the dial; keeping a tight interval for low latency costs power. Use adaptive intervals — tight during armed/active states, relaxed at rest.
- **Security:** BLE pairing/bonding with encryption; beware known BLE weaknesses (passive eavesdropping on poorly-paired links, MAC-address tracking — mitigated by resolvable private addresses). RAXHA's watch↔phone link carries health/location/event data → must be encrypted and bonded; platform transports (WatchConnectivity/Data Layer) handle this, another reason to prefer them. Never expose an unauthenticated GATT service carrying sensitive data.
- **Failure modes:**

| Failure | Cause | Defense |
|---|---|---|
| Event lost when phone in other room | Used live `sendMessage` only | Guaranteed queued path (`transferUserInfo`/`DataClient`) for events |
| Countdown stalls when link drops | Countdown ran only on phone | Watch-local countdown + phone mirror; neither sole authority |
| Duplicate alert after reconnect | Redelivered message re-triggered | Event IDs + idempotent handlers |
| Silent coverage gap (watch alone all day) | No link monitoring | Heartbeat + degraded-protection UX (Decision #14) |
| Sensitive data sniffed | Unbonded/unencrypted GATT | Platform transports; bonding + encryption; no plaintext sensitive characteristics |
| Battery drain from tight interval | Fixed low-latency connection | Adaptive connection parameters by state |
| Watch can't escalate alone | Assumed phone always present | LTE-watch direct-escalation path (Decision #2) |

---

## 6. RAXHA production shape

- **`PeerLink` interface** in the pure core; `AppleWatchLink` (WatchConnectivity) and `WearDataLink` (Data Layer) implement it. Two named methods enforce semantics: `sendLive(event)` (best-effort, low-latency) and `sendGuaranteed(event)` (queued, survives disconnection) — the naming prevents a future engineer from sending a life-critical event over the best-effort path.
- **`LinkHealthMonitor`:** heartbeat + disconnection tracking → coverage telemetry (B1 §7) → degraded-protection UX.
- **Idempotent `EventEnvelope`** (id, seq, timestamp, type) — the same envelope crosses BLE, survives reboots (Competency 2), and dedupes at the cloud (B1). One envelope design, every hop.
- **Watch-autonomy module:** local FSM + local alarm + (LTE) direct-escalation, so the watch is a complete Tier-1/2 when alone.

## 7. Founder Intelligence

**Strategic reading:** the watch↔phone link is invisible when it works and catastrophic when it doesn't — exactly the kind of unglamorous reliability surface where safety products are won. Competitors demoing on a paired-and-nearby setup never see the "phone in the other room" failure that dominates real life. **Platform reality:** Apple's WatchConnectivity is mature and constrains you to the Apple Watch↔iPhone pairing (no cross-brand); Wear OS Data Layer similarly. This means RAXHA's watch story is *within* each ecosystem — a cross-platform *family network* (the moat) sits above, in the cloud, not in the watch link. **Why LTE watches matter strategically:** an LTE watch that escalates alone removes the phone as a single point of failure — a genuine reliability differentiator worth guiding users toward. **Ledger:** ✅ WatchConnectivity/Data Layer semantics, BLE specs; 🟡 real-world reconnection latency distributions (measure in the field); 🔴 platform link internals. **Kill-relevant:** if guaranteed-delivery latency (queued path on reconnect) is too slow for the incident case on real devices, the LTE-watch-direct path becomes mandatory, not optional.

## 8. Design Review (highlights)

- **SRE:** "Show me the message taxonomy: which events go live, which go guaranteed-queued, and prove no life-critical event uses the best-effort path. Then show the reconnect-latency distribution from real devices, not a bench."
- **Security researcher:** "Your watch↔phone link carries health and location. Bonded + encrypted, resolvable private addresses, no sniffable plaintext characteristic — confirm."
- **Reliability reviewer:** "Phone in another room is the *common* case. Demo the whole incident flow with the phone across the house and the watch alone, LTE off. What still works?"
- **Investor:** "If the watch link is ecosystem-locked, where's the cross-platform value?" *(Answer: above the link, in the cloud family network — the link is plumbing, the moat is the network.)*

## 9. Constraint Exercise

Design the watch↔phone protocol for a confirmed fall where the phone is in another room (BLE marginal) and the watch is non-LTE. Constraints: the event must not be lost, the countdown must run correctly, no duplicate alerts on reconnect, battery-sane connection parameters, and the family must be alerted even if the link stays down for 3 minutes (via the phone when it reconnects, or the cloud dead-man's switch). Specify: the message taxonomy (live vs guaranteed), where the countdown runs, the idempotency scheme, the heartbeat/coverage logic, and the exact fallback sequence. One-page memo.

## 10. Chief Scientist's Verdict

**Confidence Ledger:** "WatchConnectivity/Data Layer guaranteed-queued paths survive disconnection" — ★★★★★ (documented). "BLE link is down a meaningful fraction of the time in real life" — ★★★★☆ (well-supported; exact rate 🟡, measure it). "Platform transports beat raw GATT for RAXHA's own traffic (reliability+security)" — ★★★★★. "Idempotent envelopes prevent duplicate alerts across flaky links" — ★★★★★.
**TRL:** WatchConnectivity / Data Layer — 9. BLE GATT for third-party sensors — 9. RAXHA `PeerLink` + idempotent envelope + link-health telemetry — 7 (standard, needs building). LTE-watch autonomous escalation — 8 (platform-supported; RAXHA logic to build).
**Roadmap:** *MVP:* platform transports, live+guaranteed message taxonomy, idempotent envelopes, watch-local countdown, link heartbeat. *V2:* LTE-watch direct escalation, adaptive connection parameters, cross-ecosystem via cloud. *Research:* predictive pre-buffering before likely disconnection. *Never Build:* life-critical events over best-effort only; unencrypted sensitive GATT; countdown solely on the phone.
**Competitor failures (sourced):** the general wearable-companion-app genre's documented sync-reliability complaints ("my watch didn't sync," missed notifications) — users blame the product for link failures; RAXHA's degraded-protection honesty (Decision #14) is the defense. BLE security research (documented pairing/tracking weaknesses) — why bonding/encryption and private addresses are non-negotiable for a health link.
**Kill Criteria:** if real-device reconnect latency on the guaranteed path can't meet the incident timing without LTE, make LTE-watch (or phone-present) a stated requirement rather than implying non-LTE full protection. If link-health telemetry shows chronic disconnection degrading coverage below target, surface it and guide users (keep phone nearby / get LTE watch) rather than silently under-protecting.
**Historical Failures (Historian):** early smartwatch platforms (Android Wear 1.x, B3) with flaky phone sync — reliability of the companion link, not features, drove abandonment. Fitness wearables that lost data on disconnection — data loss is a trust-killer; guaranteed-queued delivery is the lesson learned industry-wide.

## 11. Knowledge Graph Connections

- **Depends on (prior):** B1 (four-tier architecture + data plane this link implements); B2/B3 (durable on-device buffering); Competency 2 (idempotent envelope, reused here for link flakiness); Decision #4 (tier autonomy), #11 (distributed truth).
- **Depended on by (future):** every multi-tier flow — Sensor Fusion inputs crossing devices, Escalation/Response, coverage telemetry.
- **RAXHA subsystem:** the connective tissue between Tier-1 (watch) and Tier-2 (phone); feeds Escalation and coverage telemetry.
- **AI models consuming it:** none directly (transport), but carries the feature/event records models act on.
- **Sensors contributing:** none (transport layer) — carries all sensor-derived events.
- **Assumptions for validity:** link down ~10% normal; guaranteed path for events; watch autonomous when alone; bonded+encrypted. Break → coverage gap (surface it) or missed/duplicate alert (idempotency guards).
- **Confidence:** platform transports ★★★★★; real-world link availability ★★★★ (measure). See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Competency 8 pairing: **Human Gait Intelligence** (standalone; spec locked) — the bridge from physiology to HAR.*
