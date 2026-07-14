# Chapter B13 — Architecture Patterns: MVVM, Clean/Hexagonal, SOLID, DDD, DI, Offline-First

> **Paired with:** Competency 14 (Digital Biomarkers). This chapter makes explicit the code structure the *entire* engineering track has implicitly followed. Every B-chapter said "the risk engine imports nothing platform-specific; every OS surface is behind an interface" — that *is* Hexagonal Architecture, and it's why the replay harness, cross-platform reuse, and testability all worked. Now we name the patterns, so they can be applied deliberately rather than rediscovered. Taught under the Principal Architect contract.

---

## 1. Why architecture patterns matter for a safety product

Patterns aren't academic taxonomy; each one *buys a specific property* RAXHA's doctrine requires:
- **Testability** (Doctrine #10, B12): you can only replay-test a risk engine that's decoupled from the OS.
- **Cross-platform reuse** (B2/B3): one `RiskEngineCore`, two native apps, because the core depends on nothing platform-specific.
- **Offline-first** (Doctrine #2): the SOS decision can't wait for the cloud, so the architecture must treat local as the source of truth and network as an enhancement.
- **Maintainability over years** (the founder-scale horizon): a safety product lives for decades; architecture that rots becomes unsafe.
The patterns below are the *named forms* of properties you've already been enforcing.

---

## 2. SOLID — the five principles under everything

- **S**ingle Responsibility: a class/module does one thing (the fall cascade is not the delivery ladder is not the FSM).
- **O**pen/Closed: extend without modifying (add a new sensor adapter without touching the risk engine).
- **L**iskov Substitution: any `MotionSource` implementation works wherever the interface is expected (real CoreMotion, or a replay trace — the substitution that makes testing work).
- **I**nterface Segregation: small focused interfaces (`Clock`, `FallEventSource`, `AlertTransport`) not one god-interface.
- **D**ependency Inversion: **depend on abstractions, not concretions** — the risk engine depends on `MotionSource` (abstract), not `CMMotionManager` (concrete). *This is the single most important principle for RAXHA*; everything else (testability, reuse, offline) follows from it.

## 3. Hexagonal Architecture (Ports & Adapters) — the shape of RAXHA

The pattern the whole B-track has been using without naming:
```
                 ┌───────────────────────────────────┐
   ADAPTERS      │            DOMAIN CORE             │      ADAPTERS
  (platform) ───▶│  RiskEngineCore: FSM, fusion,     │◀─── (platform)
                 │  scoring, policy — PURE, no I/O    │
  CoreMotion ───▶│  depends only on PORTS (interfaces)│◀─── APNs/FCM
  HealthKit  ───▶│                                   │◀─── SQLite/Room
  Fused Loc  ───▶│                                   │◀─── BLE link
                 └───────────────────────────────────┘
       PORTS: MotionSource, VitalsSource, LocationSource, Clock,
              PeerLink, AlertTransport, HealthRecordStore, Inference
```
- **The domain core** (FSM, fusion, risk, policy) is *pure* — no `import CoreMotion`, no network, no clock-reading (Doctrine #10, B2 §6). It's the same on iOS and Android.
- **Ports** are interfaces the core defines (what it *needs*).
- **Adapters** implement ports against real platforms (production) or recordings/fakes (tests).
- **Why this is the whole game:** the replay harness (B1/B12) injects recorded-trace adapters; cross-platform reuse (B2/B3) swaps CoreMotion/SensorManager adapters behind the same port; the "reboot at T+10s" test injects a fake `Clock`. Every testability and reuse property in the curriculum traces to this shape. **Clean Architecture** (Uncle Bob) is the same idea with concentric layers (entities → use cases → interface adapters → frameworks); the dependency rule ("source code dependencies point only inward, toward the domain") is Dependency Inversion at architecture scale.

## 4. Domain-Driven Design (DDD) — modeling the problem, not the tech

RAXHA's domain has real concepts that deserve first-class models: **Incident**, **EscalationState** (the FSM), **HumanState** (the fused estimate + confidence), **RiskScore**, **Contact**, **CoverageStatus**, **DigitalBiomarker**, **PersonalBaseline**. DDD says model *these* (the ubiquitous language the whole team — and this curriculum — speaks), not database tables or API shapes. Benefits:
- **Bounded contexts:** sensing, decisioning, delivery, health-record are separate domains with clear boundaries (mirrors the tiers and the Institute structure).
- **The domain core is the DDD "domain model"** — pure, rich, the heart of the system (the Hexagonal core).
- **Ubiquitous language:** "Incident," "COUNTDOWN," "dead-man's switch," "trust budget" mean the same thing in code, docs, and design review — reducing the translation errors that kill safety systems.

## 5. MVVM — structuring the UI

- **Model** (domain state) → **ViewModel** (presentation logic, observable state) → **View** (SwiftUI/Compose, a pure function of ViewModel state).
- Why for RAXHA: the incident UI (COUNTDOWN + cancel) is a *pure render of FSM state* (B2) — MVVM makes that testable (assert "state X → cancel UI visible" without a device) and keeps UI logic out of the safety core. SwiftUI and Jetpack Compose are both declarative MVVM-friendly (the same mental model, two platforms — the B2/B3 reuse lesson at the UI layer).

## 6. Dependency Injection — wiring without coupling

DI is *how* Dependency Inversion is realized: the core declares its ports; a composition root (or a DI framework — Hilt on Android, or manual/SwiftUI environment on iOS) *injects* the concrete adapters at startup. Production wires CoreMotion + APNs + SQLite; tests wire trace-players + fake-transport + fake-clock. **DI is the seam that makes the whole hexagonal architecture assemblable and testable** — no `new CMMotionManager()` buried in the risk engine.

## 7. Offline-first & state management

- **Offline-first** (Doctrine #2): local storage is the source of truth; the network is an *enhancement that syncs*, never a *dependency the decision waits on*. The on-device FSM, durable journal (Competency 2), outbox queue (B1), and local-first data (Room/SQLite/DataStore) all embody this. A safety product that degrades gracefully offline is *architected* offline-first from day one — you can't bolt it on.
- **State management:** a single source of truth for app state (the FSM + observable state flows — `StateFlow`/Combine/SwiftUI state), unidirectional data flow (state down, events up), so state is predictable and testable. Chaotic state is unsafe state.

## 8. Failure modes (architecture edition)

| Failure | Cause | Defense |
|---|---|---|
| Can't replay-test the safety path | Core coupled to OS (no ports) | Hexagonal: pure core + ports + adapters |
| Two divergent codebases | No shared core | One domain core, platform adapters (Dependency Inversion) |
| Decision waits on network | Cloud-coupled logic | Offline-first: local source of truth (Doctrine #2) |
| UI logic entangled with safety logic | No MVVM boundary | MVVM: View = f(ViewModel state) |
| Unpredictable state bugs | Scattered mutable state | Single source of truth, unidirectional flow |
| Hidden concrete dependencies | `new Concrete()` in core | DI + composition root; core sees only ports |
| Refactors keep breaking things | Model reflects DB/API not domain | DDD: model the domain, bounded contexts |
| Architecture rots over years | No enforced boundaries | Dependency rule enforced (lint/module boundaries); the core stays pure |

## 9. RAXHA production shape (the whole engineering track, unified)

```
raxha-core/  (pure Kotlin + pure Swift, mirrored)   ← DDD domain + Hexagonal core
  domain/     Incident, EscalationFSM, HumanState, RiskScore, Baseline, Biomarker
  usecases/   detect, confirm, score, decide, escalate  (Clean "use cases")
  ports/      MotionSource, VitalsSource, LocationSource, PeerLink,
              AlertTransport, HealthRecordStore, Inference, Clock
adapters/  (per platform)   CoreMotion|SensorManager, HealthKit|HealthConnect,
              CoreML|LiteRT, APNs|FCM, SQLite|Room, WatchConnectivity|DataLayer
app-ios / app-watch / app-android / app-wear   ← MVVM UI (SwiftUI / Compose)
composition-root/   ← DI wires adapters into ports (prod) or fakes (test)
backend/   ← DDD bounded context: ingest, orchestrator, delivery (B10)
```
The two structural laws stated since B2, now named: **(1) the domain core is pure (Hexagonal + Clean dependency rule); (2) every I/O crosses a port implemented by an adapter (Dependency Inversion + DI).** Everything — testability (B12), reuse (B2/B3), offline (Doctrine #2) — is a *consequence* of these two.

## 10. Founder Intelligence

**Strategic reading:** architecture discipline is invisible until year three, when the undisciplined competitor's codebase has rotted into un-shippable spaghetti and yours still ships safely — it's a *durability* moat for a decades-long safety product. **Why it matters for hiring/scale (Institute of Leadership preview):** a clean hexagonal/DDD architecture with a pure core is *onboardable* — a new engineer learns the domain, not a tangle; the ubiquitous language (this curriculum) is the onboarding doc. **The pure core is also an IP + portability asset:** the detection/decision logic is platform-independent, so it survives platform pivots and is the crown-jewel in due diligence. **Ledger:** ✅ these patterns are industry-standard, well-documented; the work is *discipline*, not novelty. **Kill-relevant:** if the team can't maintain the dependency rule (core stays pure) under deadline pressure, testability and safety erode silently — architectural discipline is an organizational-maturity requirement, not a one-time setup.

## 11. Design Review (highlights)

- **Principal engineer:** "Show me the core has zero platform imports and every I/O is a port. That's the whole architecture; the rest is detail."
- **New-hire proxy:** "Can I understand the system from the domain model and the ubiquitous language in a day? If not, the DDD isn't done."
- **SRE:** "Offline-first: prove the decision never awaits the network, and the app degrades gracefully with no connectivity."
- **Test lead:** "Every port has a fake; the replay harness injects trace-adapters; the reboot test injects a fake clock. Confirm."

## 12. Constraint Exercise

Refactor a naïve prototype (sensor callbacks calling network directly, UI logic mixed with detection, no tests) into RAXHA's target architecture. Constraints: pure testable domain core, cross-platform reuse, offline-first, MVVM UI, DI-wired adapters, DDD domain model. Specify: the ports you extract, the domain model (entities + use cases), the adapter list per platform, the composition root, and the three tests the new architecture makes possible that the prototype couldn't support. One-page plan.

## 13. Chief Scientist's Verdict

**Confidence Ledger:** Hexagonal/Clean (pure core + ports/adapters) enabling testability + reuse — ★★★★★ (industry-proven; the curriculum's implicit backbone). Dependency Inversion as the key principle — ★★★★★. Offline-first for safety (Doctrine #2) — ★★★★★. DDD for a domain-rich safety system — ★★★★☆. MVVM for testable declarative UI — ★★★★★.
**TRL:** All patterns — 9 (standard, mature). The *disciplined application* to RAXHA — 7 (needs building + enforcement). The mirrored pure-Kotlin/pure-Swift core — 7 (real work to keep in sync).
**Roadmap:** *MVP:* hexagonal core + ports/adapters + DI + MVVM + offline-first from day one (cheap early, expensive to retrofit). *V2:* full DDD bounded contexts, enforced dependency rule (module boundaries/lint). *Never Build:* platform code in the domain core; network-coupled decisions; UI logic in the safety path; architecture without enforced boundaries (it rots).
**Competitor failures (sourced):** the industry-wide pattern of prototypes that couldn't scale/test because business logic was welded to frameworks (the reason Clean/Hexagonal exist). Big rewrites forced by architectural rot (documented across the industry) — expensive and, for a safety product, dangerous. RAXHA avoids the rewrite by architecting correctly early.
**Kill Criteria:** if the domain core can't be kept pure (platform imports creep in), fix the boundaries before adding features — a coupled core kills testability and safety. If the team can't sustain the dependency rule under pressure, invest in enforcement (module boundaries, CI checks) rather than hope.
**Historical Failures (Historian):** the "prototype welded to the framework, unshippable at scale" pattern (why these patterns were invented). Famous big-rewrite sagas (architectural debt forcing risky rewrites). For safety software specifically, the lesson is sharper: architectural rot is a *safety* regression, not just a velocity one.

## 14. Knowledge Graph Connections

- **Depends on (prior):** B1 (four-tier + FSM), B2/B3 (pure core + adapters — the implicit hexagonal shape), B12 (testing that the architecture enables), Doctrine #2 (offline-first), #10 (architecture-before-code).
- **Depended on by (future):** all further engineering (B14–16), the Institute of Leadership (onboarding/scaling on this architecture), the decades-long maintainability of the whole system.
- **RAXHA subsystem:** cross-cutting — the structure of *all* the code (core + adapters + apps + backend).
- **AI models consuming it:** none directly; the `Inference` port is how models plug into the pure core (B8/B9).
- **Sensors contributing:** none directly; sensors enter via adapters implementing ports.
- **Assumptions for validity:** domain core stays pure; every I/O crosses a port; offline-first; enforced dependency rule; DDD domain model as the shared language.
- **Confidence:** patterns ★★★★★ / disciplined RAXHA application ★★★★. See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Finale pairing: **Competency 15 — Medical AI, Clinical Validation & Regulatory** (Module 16) — where every claim across fifteen competencies meets the FDA, and V3 (Competency 14) becomes a regulatory submission. The last gate of the core arc.*
