# THREAT-MODEL-001 — Adversarial Investigation (desk, pre-code)

> Principal Systems Investigator, security lens. Adversarial thinking, not documentation: *who attacks this, how, and does a control already exist?* STRIDE-organized; each threat → vector · feasibility · impact · existing control (ADR/Doctrine/SRS) · **gap → action**. Feeds the ISO-14971 Risk Management File (B14) and B11. **The standout finding is T-7 (caregiver-as-adversary) — a genuinely new design + ethics gap, not previously surfaced anywhere in the stack.**

## Threat actors
Malicious stranger · **coercive/abusive "family" member (the non-obvious one)** · curious insider/operator · opportunistic thief (stolen device) · network/carrier-level attacker · nation-state (out of scope for v1, noted).

---

## Spoofing / False-injection

**T-1 — Spoofed fall (make RAXHA cry wolf).** *Vector:* physically shake the watch / acoustic-injection (WALNUT-class) / trigger the platform detector. *Feasibility:* Low–Med — v1 rides Apple's detector, so the attacker must fool *Apple*, not RAXHA; corroboration (posture, inactivity, HR) raises the bar. *Impact:* false dispatch, alarm fatigue, trust erosion (H-02). *Control:* multi-signal corroboration (ADR-103), platform-detector dependency. *Gap → action:* low motive; **no action** beyond existing corroboration. Note in RMF.

**T-2 — Forged alert to the family (phishing via RAXHA's channel).** *Vector:* attacker sends an SMS/call *impersonating* RAXHA ("your mother fell — tap here"). *Feasibility:* **High** — SMS sender-ID spoofing is trivial; this is the ugly cousin of H5. *Impact:* social-engineering families in their most vulnerable moment; credential theft; reputational damage to RAXHA. *Control:* none yet. *Gap → action:* **NEW — branded/verified sender identity, a documented "RAXHA will never ask you to..." family education line, and an in-app source-of-truth (the app shows the real incident; SMS is only a pointer).** Ties to A2. Add to RFC/workstream list.

**T-3 — Spoofed incident ingest (fake incidents to the cloud).** *Vector:* forge `EventEnvelope` to the backend. *Feasibility:* Low. *Impact:* fake escalations. *Control:* authenticated device-origin ingest (SRS-601, ADR-106), consent-gated recipients (SRS-805). *Gap → action:* **covered** — verify in VV-605.

## Tampering / Denial (the dangerous direction — suppress a *real* emergency)

**T-4 — Suppress a real alert.** *Vector:* jam network / kill the watch / acoustic-injection to *prevent* detection / force-quit the app. *Feasibility:* Med (physical access). *Impact:* **the worst — a real emergency goes unheard (H-01).** *Control:* dead-man's switch on vanished heartbeat (D11, SRS-602), multi-path delivery (SRS-604), coverage telemetry surfaces a killed app (D09). *Gap → action:* **mostly covered** — but the dead-man's switch only fires for incidents it *heard about* (AUDIT-001 H2); a suppress-before-incident attack is invisible. Coverage telemetry is the only backstop. Accept + document; strengthen with SPIKE-004/006 evidence.

**T-5 — Replay attack.** *Vector:* re-send a captured incident/ack event. *Feasibility:* Low. *Impact:* duplicate escalation / false ack. *Control:* idempotency + `eventId`/`alertId` dedup (D06, SRS-503), auth. *Gap → action:* **covered** — ensure acks are idempotent + bound to incident (verify VV-206).

**T-6 — GPS/BLE spoofing.** *Vector:* fake location to misdirect responders; BLE MITM watch↔phone. *Feasibility:* Low–Med. *Impact:* responders misdirected (H-05); link compromise. *Control:* location plausibility (C6), platform BLE pairing security, uncertainty-always-shown (D15). *Gap → action:* low motive; **covered** by existing plausibility + platform security.

## Elevation / Repudiation / Info-disclosure — **the abuse vectors**

**T-7 — ⚠️ Caregiver-as-adversary (the surveillance/coercive-control vector).** *Vector:* the "family" is not always benign. The adult child who owns the account gains **continuous location, coverage patterns, activity, and presence** of the elder — a purpose-built stalking/coercive-control tool. Elder-abuse is overwhelmingly perpetrated by family. *Feasibility:* **High — it's not an attack on the system, it's the system used as designed by a bad actor.** *Impact:* the product becomes an instrument of domestic abuse; severe ethical + legal + reputational harm; directly contradicts the mission ("helps the right people"). *Control:* **NONE. This is a real, previously-unsurfaced design gap.** The consent model (PDR-011) gates *contacts receiving alerts*, but says nothing about **the elder's agency over their own monitoring** — who can see location, who can change settings, whether Margaret can review/revoke, whether continuous location is even exposed to family outside incidents (it should NOT be — D21 minimization actually helps here, if enforced). *Gap → action:* **NEW — HIGH PRIORITY. Proposed RFC-007:** (a) elder retains visibility + veto over who monitors and what they see; (b) family gets **incident-time** location only, not continuous tracking (this is already the D21/ADR-111 posture — make it an explicit *anti-surveillance* product guarantee, not just a privacy one); (c) tamper-evident settings changes visible to the elder; (d) an abuse/coercion review in the ethics section before beta. *This reframes a privacy control as a safety control against a threat actor the product was assuming didn't exist.*

**T-8 — Account takeover (SIM swap / Apple ID compromise).** *Vector:* SIM-swap to intercept SMS alerts + 2FA; compromise the elder's Apple ID → full device control. *Feasibility:* Med (SIM swap is common; elders are soft targets for social engineering). *Impact:* alert interception, account hijack, coverage sabotage, data access. *Control:* partial — depends on account-security design (unspecified). *Gap → action:* **NEW — MFA hardening (prefer app-based/passkey over SMS-2FA), account-recovery hardening, anomaly detection on account changes.** Note: Apple ID security is outside RAXHA's boundary but its compromise defeats RAXHA — document as an inherited risk.

**T-9 — Insider / operator misuse.** *Vector:* a RAXHA employee or acquirer mines location/health data (the Life360 pattern). *Feasibility:* Low *if* architecture holds. *Impact:* mass privacy breach, trust collapse. *Control:* **strong — minimization means the data largely doesn't exist to misuse** (D21, ADR-111, SRS-804: no sellable store). *Gap → action:* **covered by design** — this is where the architecture's privacy bet pays off; verify VV-706 schema audit.

**T-10 — Sensor/behavioral fingerprinting.** *Vector:* AccelPrint-class device fingerprinting; gait as a biometric (v2). *Feasibility:* research-grade. *Impact:* de-anonymization. *Control:* on-device processing, minimization (D21). *Gap → action:* low v1 priority; matters when gait ships (Competency-8 domain 3 already flagged this).

---

## Findings summary

| Threat | Severity | Status |
|---|---|---|
| **T-7 Caregiver-as-adversary** | **High** | **NEW GAP → RFC-007 (anti-surveillance guarantee + elder agency)** |
| T-2 Forged alert to family | High | NEW GAP → verified sender + in-app source-of-truth (with A2) |
| T-8 Account takeover (SIM/Apple ID) | Med–High | NEW GAP → MFA/recovery hardening |
| T-4 Suppress real alert | High | Mostly covered (dead-man + coverage); residual documented |
| T-1/3/5/6 spoof/replay/GPS/BLE | Low–Med | Covered by corroboration/idempotency/auth/plausibility |
| T-9 insider misuse | High-if-unmitigated | **Covered by minimization — the privacy bet working** |
| T-10 fingerprinting | Low (v1) | Deferred to gait/v2 |

**The one that matters most: T-7.** Every other threat is a conventional security problem with a conventional control. T-7 is different — it's the recognition that *"family safety" assumes the family is safe*, and for a non-trivial fraction of elders that assumption is false. The fix is partly already present (D21 minimization means RAXHA *shouldn't* expose continuous location to family) but was framed as privacy, not as **protection against a hostile caregiver** — and it needs to become an explicit product guarantee plus an elder-agency design, reviewed before any beta. Recommended as **RFC-007** for founder decision; logged as a Notebook-A-class discovery (reality — the human threat model — arguing before code).
