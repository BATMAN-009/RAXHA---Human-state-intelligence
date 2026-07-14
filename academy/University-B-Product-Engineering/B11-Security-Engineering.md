# Chapter B11 — Security Engineering: Keychain/Keystore, E2E Encryption, TEE

> **Paired with:** Competency 12 (the Decision Engine). The Decision Engine decides to summon help based on the most intimate data a person emits — health, location, gait, routine. This chapter protects all of it: the data at rest, the alert in transit, the keys that guard both, and the decision logic itself (a high-value attack target — suppress a real alarm or fire false ones). Security for RAXHA is not a feature bolted on; it's the precondition for the trust the whole product runs on. Taught under the Principal Architect contract.

---

## 1. The threat model (name your adversaries first)

Security engineering starts by enumerating who you're defending against and what they want:
- **Device thief / lost phone:** wants the health/location data at rest, and could try to forge state (recall Competency 2/3: a boot-readable journal that's also *tamper-able*).
- **Network attacker (MITM):** wants to read or alter the alert/location channel in transit.
- **Malicious/compromised backend or insider:** the reason for **end-to-end** encryption and **data minimization** — the server shouldn't hold what it doesn't need in plaintext (the Life360 lesson: what you centralize can be sold, subpoenaed, or breached).
- **Sensor/signal attacker:** spoofing/injection (WALNUT, C1/C2; fake beacons, C7) — defended by cross-sensor consistency (C10), not crypto.
- **Model/decision attacker:** wants to suppress a real alarm or trigger false ones — defended by signed models/thresholds (B8/B9) and tamper-evidence.
- **The operator itself (RAXHA):** the no-monetization doctrine means designing so RAXHA *cannot* misuse data even if it wanted to — architecture as a constraint on the company, not just outsiders.

**Principle: least privilege + data minimization + defense in depth.** Every layer assumes the one outside it may be breached.

---

## 2. Where secrets live: Keychain, Keystore, and hardware-backed keys

- **iOS Keychain:** the OS-managed encrypted store for credentials, tokens, keys — with **Data Protection classes** (the same classes from Competency 2/3: `afterFirstUnlock` for things needed post-reboot-pre-unlock, `whenUnlocked` for higher security). Keychain items can be **Secure-Enclave-backed** (keys generated in and never leaving the Enclave).
- **Android Keystore:** the equivalent — keys stored in a system credential store, usable but not exportable, optionally **hardware-backed (TEE)** or **StrongBox** (a dedicated secure element on supported devices).
- **The Secure Enclave / TEE / StrongBox (hardware root of trust):** a separate secure processor that generates and holds keys such that *even a fully compromised OS cannot extract them* — it can only *request operations* (sign, decrypt) that the hardware performs. This is where RAXHA's most sensitive keys live: the ones protecting health data, the device-identity key, and (from B8/B9) the key that verifies signed model/threshold updates.

**The Competency-3 resolution, completed:** the tamper problem you found (a keyed MAC on the boot journal needs a key, and a boot-readable key is forgeable) is solved *here* — the signing key lives in the **TEE/StrongBox**, boot-accessible for *operations* without exposing the key material, so the journal can be integrity-checked at boot without the key being stealable. Or the cloud remains tamper-authoritative (Decision #11). Both are hardware-root-of-trust or distributed-truth answers.

---

## 3. Encryption: at rest and end-to-end in transit

- **At rest:** OS full-device encryption + app-level encryption of sensitive stores (health, location, gait templates, contacts) with keys in Keychain/Keystore (Enclave-backed). Data Protection class chosen per the availability/security trade-off (Competency 2/3).
- **In transit:** TLS everywhere (+ certificate pinning for the alert channel — defend against MITM even with a compromised CA).
- **End-to-end encryption (E2E) for the alert/location payload:** the sensitive contents (health context, precise location, medical ID) encrypted so that *only the intended recipients* (the user's chosen contacts) can read them — the backend routes ciphertext it cannot read. This operationalizes data minimization: even a breached RAXHA backend leaks no health/location plaintext. (E2E has real key-management complexity — recovery, multi-recipient, contact key distribution — a deliberate engineering investment justified by the sensitivity.)
- **Biometric-template protection (from C8):** gait/wearer-verification templates encrypted, Enclave-protected, **on-device only, never centralized** — the structural defense against the KIT-style identity threat.

## 4. Protecting the decision and the model

- **Signed, versioned model & threshold updates** (B8/B9 control plane): the Decision Engine's models *and its policy thresholds* are safety-critical config; updates are signed (key in TEE-verified), canaried, shadow-tested, rollback-able. An attacker who could push a threshold change could suppress alarms fleet-wide — so this is treated with firmware-grade security.
- **Tamper-evidence** on the on-device decision logic and the FSM journal; cross-sensor consistency (C10) as integrity against sensor spoofing.
- **Authenticated ingest** (B10): only the user's authenticated device can create their incidents — no spoofed emergencies.

## 5. Privacy engineering (the doctrine, enforced in code)

- **Data minimization:** collect/retain/transmit the least that saves the life (raw stays on-device — Doctrine #5; events/ciphertext cross the wire).
- **On-device processing** (TinyML/Core ML, B8/B9): the risk engine runs locally, so raw biometric data never needs to leave — privacy *and* the on-device-decision doctrine (Doctrine #2) served by the same architecture.
- **Incident-only retention** for location (B6/B10); **no movement/health database** to breach or sell (Life360 lesson, Decision-level).
- **Federated learning preview (Module 13):** personalize models on-device, share only encrypted/aggregated updates — learn from the fleet without centralizing the most sensitive data. Secure aggregation ensures the server sees only the sum, not any individual's contribution.
- **Consent & transparency:** contacts consent to being responders (B10); users consent to sensing; the system is honest about what it knows and can't (Decision #13/#15).

## 6. Failure modes

| Failure | Cause | Defense |
|---|---|---|
| Health/location plaintext leaked in a backend breach | Server holds sensitive data readable | E2E encryption; data minimization; on-device processing |
| Keys extracted from a stolen device | Keys in software/app storage | Keychain/Keystore + Secure Enclave/StrongBox; non-exportable keys |
| Forged boot journal suppresses alarm | Keyless checksum / boot-readable key | TEE-held signing key; or cloud tamper-authoritative (Decision #11) |
| Malicious model/threshold pushed fleet-wide | Unsigned control-plane update | Signed (TEE-verified), canaried, shadow-tested, rollback |
| MITM reads/alters alert | Plain TLS with compromised CA | Certificate pinning; E2E payload encryption |
| Spoofed emergency incidents | Unauthenticated ingest | Device authentication; incident provenance |
| Gait/biometric template stolen or centralized | Template in cloud / unprotected | On-device only; Enclave-protected; never centralized |
| Company misuse of data | Data centralized "just in case" | Architectural minimization — can't misuse what you don't hold |

## 7. Founder Intelligence

**Strategic reading:** security/privacy is RAXHA's trust moat made structural — the post-Life360 differentiator ("we *cannot* sell your location, by architecture") only works if it's real (E2E, minimization, on-device, no central DB). **Why incumbents are exposed:** business models that monetize data create the incentive to centralize it; RAXHA's no-monetization doctrine lets it architect for minimization, which is a genuine, defensible, *marketable* difference. **Platform gift:** Apple/Google hand you Enclave/StrongBox/Keychain/Keystore — best-in-class hardware security you compose, not build. **The E2E trade-off is a strategic choice:** it complicates features (the server can't read data to do clever things) but *is* the privacy promise — for a safety product handling health+location, it's the right call. **Ledger:** ✅ Keychain/Keystore/Enclave/StrongBox capabilities, TLS/pinning, E2E patterns; 🟡 exact TEE guarantees per device; 🔴 nothing critical hidden — security here is well-documented, the work is discipline. **Kill-relevant:** if E2E can't be delivered without breaking the safety flow (e.g., server needs to read location to route to services), scope it carefully (minimize + short-retention where E2E isn't feasible) and be honest — never claim E2E you don't have.

## 8. Design Review (highlights)

- **Security researcher:** "Threat-model every link. Prove keys are Enclave/StrongBox-backed and non-exportable, model updates are signed, ingest is authenticated, and the boot journal can't be forged (Competency 3's real answer lives here)."
- **Privacy advocate:** "E2E for health/location payloads, on-device processing, incident-only retention, no central health/movement DB. Show me the server holds ciphertext, not plaintext."
- **Regulator (Module 16 preview):** "Health data security is regulated (HIPAA/GDPR special category). Encryption, access control, audit, breach posture — documented."
- **SRE:** "Certificate pinning + key rotation + signed updates without bricking devices. Show the key-management and rotation plan."
- **Ethicist:** "Consent for sensing and for being a contact; transparency about inference. Security protects data; ethics governs its use."

## 9. Constraint Exercise

Design RAXHA's security architecture end-to-end: keys (where each lives), at-rest encryption (+ Data Protection classes tied to the Competency-2/3 reboot cases), E2E for the alert/location payload, signed model/threshold updates, biometric-template protection, and authenticated ingest — under data-minimization and no-central-sensitive-DB constraints. Constraints: the safety flow must still work on a locked/rebooted phone (Competency 2/3), the server must route alerts without reading health/location plaintext, and privacy claims must be architecturally true. Specify each mechanism, the threat it defends, and where the doctrine (Decisions #2/#5/#11) is enforced. One-page memo.

## 10. Chief Scientist's Verdict

**Confidence Ledger:** Keychain/Keystore + Secure Enclave/StrongBox for non-exportable keys — ★★★★★ (mature, hardware-backed). E2E encryption for sensitive payloads — ★★★★★ (proven; key-management is the work). TEE-held signing solving the boot-journal tamper problem — ★★★★☆. Data minimization / on-device processing as privacy defense — ★★★★★. "Architectural non-monetization" as a real (not just policy) guarantee — ★★★★☆ (real if enforced end-to-end).
**TRL:** Keychain/Keystore/Enclave/StrongBox usage — 9. TLS + pinning — 9. E2E payload encryption — 8 (proven; RAXHA integration + key-management to build). Signed model/threshold OTA — 8. Federated/secure-aggregation (Module 13) — 6–7.
**Roadmap:** *MVP:* Enclave/StrongBox keys, at-rest encryption with correct Data Protection classes, TLS+pinning, authenticated ingest, signed model updates, incident-only retention. *V2:* E2E alert/location payloads, biometric-template Enclave protection, key rotation. *V3:* federated learning + secure aggregation (Module 13). *Never Build:* central plaintext health/location store; software-only key storage; unsigned safety-config updates; privacy claims not architecturally enforced.
**Competitor failures (sourced):** Life360 location-data-broker sale (the centralization-enables-misuse lesson — architecture, not policy, is the fix). Documented health-app breaches and data-sale FTC actions (the cost of holding sensitive data you don't protect/minimize). Backend breaches across industries exposing plaintext sensitive data (why E2E + minimization). Boot/lock-screen bypass research (why hardware-root-of-trust, not software checks).
**Kill Criteria:** if E2E can't be delivered for a claimed-private data flow, don't market it as E2E — minimize + short-retain and disclose honestly. If keys can't be hardware-backed on a device class, treat that class as lower-assurance and scope accordingly. If the safety flow can't work with the required Data Protection classes on locked/rebooted phones (Competency 2/3), fix the storage architecture before shipping — availability and security must both hold.
**Historical Failures (Historian):** Life360 (centralization → monetization → trust collapse). Major health/fitness app breaches (plaintext sensitive data exposed — minimization + encryption would have contained them). Lock-screen/boot-security bypasses (hardware root of trust is the durable answer). The recurring lesson: **for a safety product, a privacy/security failure is an existential-trust failure — it doesn't just leak data, it ends the product's reason to be trusted.**

## 11. Knowledge Graph Connections

- **Depends on (prior):** Competency 2/3 (Data Protection classes, Direct Boot, the tamper problem this chapter resolves), B8/B9 (signed model updates), B10 (authenticated ingest, retention), C8 (biometric templates), Decisions #2/#5/#11.
- **Depended on by (future):** Module 13 (privacy-preserving/federated learning builds on this), Module 16 (regulatory security requirements), the whole product's trust posture.
- **RAXHA subsystem:** cross-cutting — protects every subsystem's data, keys, decision logic, and the response channel.
- **AI models consuming it:** none directly; protects the models (signed updates) and their training data (minimization/federation).
- **Sensors contributing:** none directly; protects all sensor-derived data.
- **Assumptions for validity:** hardware-backed non-exportable keys; E2E for sensitive payloads; signed safety-config; minimization/no-central-sensitive-DB; safety flow works within the security constraints (Competency 2/3).
- **Confidence:** hardware key protection + E2E ★★★★★ / architectural non-monetization ★★★★. See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Competency 13 pairing: **Privacy-Preserving AI — Federated Learning, Differential Privacy, Secure Aggregation** (Module 13) + **B12 — Testing, Release Engineering & Fleet Observability**. Then the final stretch: Digital Biomarkers/Phenotyping (Module 10) and Medical AI / Clinical Validation / Regulatory (Module 16) — where RAXHA's claims meet the FDA.*
