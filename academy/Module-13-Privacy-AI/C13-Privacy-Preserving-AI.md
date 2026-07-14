# Competency 13 (Science) — Privacy-Preserving AI

> **Why this resolves the deepest tension in RAXHA.** Two doctrines the curriculum has repeated are in direct conflict. The **data flywheel** (C9/C11): RAXHA's models get better with the fleet's real-world data — the compounding moat. The **privacy doctrine** (#5, B11): the most sensitive data a person emits (HRV, gait, location, routine) must stay on-device and never be centralized. You cannot both centralize data to train and never centralize data. Privacy-preserving AI is the resolution: **learn from the fleet without collecting the fleet's data.** This is not a compromise between the two doctrines — it's the technique that lets RAXHA honor both, and it's what makes "we can't sell what we never hold" (B11) compatible with "our models improve with scale."

---

## 1. Definition

**Privacy-preserving AI** is a family of techniques that train, personalize, and run models on sensitive data while provably limiting what any party learns about any individual. The four that matter for RAXHA:
- **Federated Learning (FL):** train on-device on local data; send only *model updates* (gradients/weights), never raw data, to a server that aggregates them into a global model.
- **Secure Aggregation:** cryptographic protocol so the server sees only the *sum* of many devices' updates, never any individual's.
- **Differential Privacy (DP):** add calibrated noise so the presence or absence of any single person's data provably can't be inferred from the output — with a quantified **privacy budget (ε)**.
- **Confidential computation** (TEE / homomorphic encryption): compute on data the computing party cannot read.

The goal: the global model improves; no individual's raw data, and provably little about any individual, ever leaves their device or becomes learnable.

---

## 2. History

- **Differential Privacy:** Dwork, McSherry, Nissim & Smith (2006) — the foundational formalization; gave privacy a *mathematical definition* (ε-DP) rather than a vague promise. Deployed by Apple (2016, on-device analytics), Google (RAPPOR), the US Census (2020).
- **Federated Learning:** McMahan et al. (Google, 2016–17) — "Communication-Efficient Learning of Deep Networks from Decentralized Data" (FedAvg); built for Gboard (learn from typing without uploading keystrokes) — a directly analogous problem to RAXHA (learn from sensitive on-device behavior).
- **Secure Aggregation:** Bonawitz et al. (Google, 2017) — cryptographic protocol making FL updates individually invisible to the server.
- **Homomorphic Encryption:** Gentry (2009) — first fully-homomorphic scheme (compute arbitrary functions on ciphertext); still expensive, maturing.
- **TEEs** (Intel SGX, ARM TrustZone, Secure Enclave): hardware confidential computation, 2010s→.

---

## 3. Scientific Foundation

### 3.1 Why naive "keep data on device" isn't enough
Federated learning *alone* leaks: the model updates a device sends can be **inverted** to partially reconstruct its training data (gradient-leakage attacks), and **membership inference** can tell whether a specific person was in the training set. So FL is necessary but not sufficient — it must be combined with secure aggregation (hide individual updates) and/or DP (bound what any update reveals). *This is the recurring RAXHA lesson — "on-device" is a start, not a guarantee — applied to learning.*

### 3.2 Differential Privacy, precisely
An algorithm is **ε-differentially private** if its output distribution changes by at most a factor of e^ε when any single individual's data is added or removed. Small ε = strong privacy (output barely depends on any individual) but more noise (less accuracy); large ε = weaker privacy, more accuracy. The **ε is a budget you spend** — every query/training round consumes some, and it composes (spend too much across many rounds and privacy erodes). The core trade-off: **privacy vs utility**, made quantitative. For RAXHA, DP on federated updates bounds what the aggregated model can reveal about any user's HRV/gait/routine.

### 3.3 Secure Aggregation
Devices cryptographically mask their updates so masks cancel *only when summed* across many participants — the server computes the aggregate (usable for training) but learns nothing about any single device's contribution (the masks make an individual update look random). Combined with DP, you get: server sees only a noised sum of many updates → strong per-individual privacy + a usable global model.

### 3.4 On-device personalization vs global learning (two directions)
- **Global → device:** FL improves the *shared* model from everyone (the flywheel, privately).
- **Device → device:** on-device fine-tuning personalizes the *local* model to the user (Core ML `MLUpdateTask`, B9; Decision #16) — the raw data and the personalized model never leave. RAXHA uses both: FL for population improvement, on-device personalization for the individual — neither centralizes raw data.

### 3.5 Confidential computation
Where some server-side computation on sensitive data is unavoidable, do it in a **TEE** (the server operator can't see inside) or, someday, via **homomorphic encryption** (compute on ciphertext). Expensive; used selectively.

---

## 4–8. Working, Data, Algorithms (RAXHA-specific)

**The RAXHA privacy-preserving learning loop:**
```
on each device: local data (raw, never leaves)
   → local training/personalization (on-device, Decision #16)
   → compute model update (gradient/weights)
   → clip + add DP noise (bound individual contribution)
   → secure-aggregation mask
   → server: sum masked+noised updates from many devices (sees only the aggregate)
   → updated global model → signed, shadow-tested, canaried push back to devices (B8/B9/B11)
```
**What RAXHA learns this way:** better population fall/HAR/anomaly models, refined baselines, improved calibration — from real-world data (including the precious rare falls) — *without* any raw sensor stream, gait template, or location history ever being collected. The data flywheel (C9/C11) spins, privately.

**The label problem meets privacy:** the rare real-world falls that make the flywheel valuable are also the most sensitive events — FL+DP lets them improve the model without a central database of people's worst moments.

**Attacks to defend (the honesty):** gradient leakage (→ secure agg + DP), membership inference (→ DP), model-poisoning by malicious devices (→ robust aggregation, anomaly detection on updates), and the *privacy-budget-exhaustion* failure (spend ε too freely across rounds → erode the guarantee). DP's ε must be *tracked and bounded* like a real budget.

## 9–12. Products, Research, Security, Medical (brief)

**Products:** Google Gboard (FL for typing), Apple on-device DP analytics, federated approaches emerging in health wearables — the direct precedents. **Research:** Dwork 2006 (DP), McMahan 2017 (FL), Bonawitz 2017 (secure agg), Gentry 2009 (HE); active work on FL for health, DP-utility trade-offs, robust/poisoning-resistant FL. **Open problems:** the privacy-utility frontier for small ε on health data, poisoning-robust FL at scale, personalization + FL together, and honest ε accounting. **Security:** privacy-preserving AI *is* security engineering (B11) applied to learning; the threats (inversion, membership, poisoning) are why naive FL fails. **Medical:** health-data privacy is regulated (HIPAA/GDPR special category — Module 16); FL+DP is increasingly how health ML is done compliantly, and "we never centralized your health data" is both a regulatory strength and a trust differentiator.

## 13. Engineering for RAXHA

1. **FL + secure aggregation + DP together** (not FL alone) for population learning — the flywheel without the database.
2. **On-device personalization** (Core ML `MLUpdateTask`/equivalent) for the individual (Decision #16) — raw data and personalized model stay local.
3. **Track the DP privacy budget** (ε) as a real, bounded, monitored resource — don't let many training rounds silently erode the guarantee.
4. **Robust aggregation** against poisoning (a safety model must resist malicious update injection).
5. **Signed, shadow-tested global-model pushes** (B8/B9/B11) — the learning loop closes through the safe deployment pipeline.
6. **Honesty about the guarantee** (Decision #13/Confidence Ledger): state the ε, don't over-claim "perfect privacy"; DP is *quantified* privacy, not magic.
7. **TEE for any unavoidable server-side sensitive computation.**

## 14. Failure Analysis

| Failure | Mechanism | Mitigation |
|---|---|---|
| Raw data reconstructed from updates | Gradient leakage in naive FL | Secure aggregation + DP noise |
| Individual identified in training set | Membership inference | DP with bounded ε |
| Privacy guarantee silently erodes | ε over-spent across rounds | Track/bound the privacy budget; composition accounting |
| Malicious device poisons the model | Unvalidated FL updates | Robust aggregation; anomaly detection on updates; signed participation |
| Over-claimed "perfect privacy" | DP framed as absolute | Honest ε disclosure (Confidence Ledger) |
| Utility collapses at strong privacy | ε too small / too much noise | Tune privacy-utility; personalization to recover accuracy |
| Server-side sensitive compute leaks | Plaintext processing | TEE / minimize / avoid |

## 15. RAXHA Application — distilled

- **Use as:** the resolution of the data-flywheel-vs-privacy tension — learn from the fleet (including precious rare falls) and personalize per user, all without centralizing raw biometric/location data.
- **Do NOT use as:** an excuse to over-claim ("perfectly private" — it's *quantified* private); FL-alone (leaks); an unbounded-ε system; a poisoning-naive aggregator.
- **One-liner:** *privacy-preserving AI is how RAXHA gets smarter from millions of people's data while holding none of it — turning "we can't sell what we never collect" from a limitation into the engine of the moat.*

## 16. Future

Practical strong-ε DP for health; poisoning-robust FL; FL+personalization+calibration unified; efficient homomorphic/TEE computation; federated *analytics* (fleet insights without data); on-device continual learning with formal privacy — the "learn everywhere, collect nowhere" endpoint.

## 17. Mastery Test — Competency 13

1. State the data-flywheel-vs-privacy tension precisely, and explain how FL+secure-aggregation+DP resolves it without compromising either doctrine.
2. Why is federated learning *alone* insufficient? Name two attacks and their defenses.
3. Explain differential privacy's ε as a budget: the privacy-utility trade-off and what "spending ε" across rounds means.
4. How do the two learning directions (global FL vs on-device personalization) both avoid centralizing raw data, and which serves Decision #16?
5. Why is "we never centralized your health data" both a regulatory strength (Module 16) and a trust differentiator (B11/Life360)?
6. Why must RAXHA disclose its ε honestly rather than claim "perfect privacy" (tie to the Confidence Ledger)?
7. **[Standing gate question]** If RAXHA shipped federated learning tomorrow, what's the single most likely field failure — scientific, platform, or product?

## 18. Founder Intelligence

**Why hasn't this been "solved"?** The privacy-utility frontier for strong DP on health data is genuinely hard (strong privacy costs accuracy); poisoning-robust FL at scale is open; and honest ε accounting is subtle. But the *techniques* are proven (Google/Apple ship them) — the work is disciplined integration. **The moat:** privacy-preserving learning lets RAXHA's flywheel spin *without* the liability, regulatory burden, and trust-risk of a central health/location database — a structural advantage over any competitor whose business model centralizes data. "We get smarter with scale AND we hold none of your data" is a genuinely differentiated, defensible, *marketable* position post-Life360. **WHOOP/Oura/etc.** largely centralize (their model needs it); RAXHA's safety+privacy framing makes FL the right architecture. **Why doesn't everyone?** FL+DP+secure-agg is engineering-heavy and utility-costly; most consumer companies find centralizing easier and monetizable — RAXHA's no-monetization doctrine removes the incentive to centralize, making FL natural. **Startup opportunities:** privacy-preserving health-ML infrastructure; federated learning for regulated health data; DP-as-a-service. **RAXHA strategy:** FL+DP is what makes the flywheel and the privacy promise *simultaneously* true — invest in it as core infrastructure, disclose ε honestly, and market architectural privacy as the differentiator. **PhD gaps:** strong-ε health DP, poisoning-robust FL, unified FL+personalization+calibration, honest composition accounting. **Patents:** FL/secure-agg/DP families (Google/Apple — query `federated learning secure aggregation assignee:X`). **Ledger:** ✅ FL/DP/secure-agg methods and deployments (Google/Apple), the math; 🟡 optimal health-data configs; 🔴 nothing critical hidden — the science is open, the work is discipline.

## 19. Design Review (highlights)

- **Privacy advocate:** "FL alone leaks — show me secure aggregation AND a bounded, tracked ε. And disclose the ε; 'private' without a number is marketing."
- **Chief Scientist:** "Show the privacy-utility trade-off you chose and that model quality survives it. And prove poisoning-robustness — a safety model can't be corrupted by malicious devices."
- **Regulator (Module 16):** "Not centralizing health data is a strong compliance posture. Document the DP guarantee and the data-flow — auditable."
- **Investor:** "Flywheel + no central data is the differentiated position. Prove the models actually improve federated, at your privacy setting."
- **Security researcher:** "Gradient leakage, membership inference, poisoning — walk me through each defense, not just 'we use FL.'"

## 20. Constraint Exercise

Design RAXHA's federated learning system to improve the population fall model (including rare real-world falls) without centralizing any raw data. Constraints: secure aggregation (server sees only sums), a bounded/tracked DP ε (disclosed honestly), poisoning-robustness, on-device personalization (Decision #16) alongside, and closing the loop through signed/shadow-tested deployment (B8/B9/B11). Specify: the on-device training + update flow, the secure-agg + DP mechanism, the ε budget policy, the poisoning defense, and how the rare-fall data improves the model without a central database. One-page memo.

## 21. Chief Scientist's Verdict

**Confidence Ledger:** FL to learn without centralizing raw data — ★★★★★ (deployed, Google/Apple). Secure aggregation hiding individual updates — ★★★★★. DP with bounded ε for provable per-individual privacy — ★★★★★ (foundational). Strong-ε DP preserving health-model *utility* — ★★★☆☆ (**the hard privacy-utility frontier**). Poisoning-robust FL at scale — ★★★☆☆. Homomorphic encryption for practical health compute — ★★☆☆☆ (expensive, emerging).
**TRL:** FL / secure agg / DP — 8–9 (shipped at scale by big tech; RAXHA integration to build). On-device personalization — 8. Poisoning-robust FL — 5–6. Practical HE — 3–4. Honest ε accounting — 7.
**Roadmap:** *MVP:* on-device personalization (no data egress) + centralized-nothing baseline; opt-in shadow-data with strict minimization. *V2:* FL + secure aggregation + bounded DP for population models. *V3:* poisoning-robust FL, federated analytics, TEE where needed. *Never Build:* FL without secure-agg/DP (leaks); unbounded-ε; "perfect privacy" claims; central raw health/location store.
**Competitor failures (sourced):** documented gradient-leakage / membership-inference research against naive FL (why FL-alone is insufficient). DP deployments criticized for weak (large) ε that provided little real privacy (the "DP-washing" risk — disclose ε honestly). Central health-data breaches/sales (the centralized alternative's failure mode — the reason FL exists for RAXHA).
**Kill Criteria:** if FL+DP can't preserve enough model utility at an honest ε, lead with on-device personalization + minimal opt-in data rather than over-claim FL. If poisoning-robustness can't be assured, gate FL participation (attestation) or delay FL. If ε can't be honestly bounded and disclosed, don't market DP.
**Historical Failures (Historian):** "DP-washing" (products claiming DP with ε so large it was near-meaningless — documented critiques) — honest ε disclosure is the antidote (Confidence Ledger). Naive-FL privacy-attack demonstrations (the research that proved on-device≠private without more) — the recurring RAXHA lesson at the learning layer. Central health-data breaches across the industry — the failure FL+minimization exists to prevent.

## 22. Knowledge Graph Connections

- **Depends on (prior):** C9/C11 (the data flywheel this makes private), B8/B9 (on-device models + signed deployment), B11 (security/TEE/keys), Decisions #5 (data plane), #16 (personalize), #18 (calibration to preserve).
- **Depended on by (future):** Module 16 (regulatory — privacy compliance), the whole product's flywheel + trust posture; B12 (testing the FL pipeline).
- **RAXHA subsystem:** the learning infrastructure — improves every model privately; personalization engine.
- **AI models consuming it:** all trainable models (fall/HAR/anomaly/baseline/calibration) improved via FL; personalized via on-device learning.
- **Sensors contributing:** all — their data trains models on-device without leaving.
- **Assumptions for validity:** FL never alone (secure-agg + DP); bounded/tracked/disclosed ε; poisoning-robust; personalized locally; honest privacy claims.
- **Confidence:** FL/secure-agg/DP methods ★★★★★ / strong-ε health utility ★★★. See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Paired chapter this competency: **B12 — Testing, Release Engineering & Fleet Observability** — including the hardest question your Competency-12 answer raised: how do you test a system for the emergencies it must never miss, when you can't wait for real ones?*
