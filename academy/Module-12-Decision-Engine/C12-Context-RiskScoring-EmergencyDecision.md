# Competency 12 (Science) — Context Awareness, Risk Scoring & the Emergency Decision

> **Why this is the summit of the intelligence graph.** Eleven competencies produced a calibrated, personalized, uncertainty-aware estimate of the human state, plus anomaly candidates. Nothing below this layer is allowed to decide whether a family is called (Decision #17). *This* is that layer — the Decision Engine — and its job is not detection. Its job is **appropriate interruption** (Decision #19): converting all the evidence into a single answer to "is this abnormal enough, trustworthy enough, and important enough to spend a unit of a family's finite trust?" Everything before was perception; this is judgment.

---

## 1. Definition

The Decision Engine is three cooperating layers:
1. **Context Awareness** — assembling the *situation*: the fused human-state estimate (C10) + environment (location/place, C6/C7) + time + activity (C9) + history + coverage/sensor confidence into a rich, structured picture of "what is happening, where, to whom, when, and how sure are we."
2. **Risk Scoring** — converting that context into a **calibrated probability (or severity) that a genuine emergency is occurring**, under an explicit cost model. This is a *decision-theoretic* step, not a classifier.
3. **The Emergency Decision (Policy)** — converting risk into *action* (do nothing / observe / check-in / countdown / alert / escalate to services), spending trust only when justified (Decision #19), and doing so *explainably* (Decision #15).

Context perceives the situation; Risk quantifies the danger; Policy decides the interruption. Only Risk and Policy may convert evidence into life-critical action (Decision #17).

---

## 2. History

Context-aware computing (Schilit & Want, 1994; Dey's context toolkit, 2001) framed "context" as first-class. **Decision theory** (von Neumann–Morgenstern expected utility, 1944; Wald's statistical decision theory, 1950) gives the formal machinery: act to maximize expected utility under uncertainty and an explicit loss function. **Medical early-warning scores** — MEWS, then **NEWS/NEWS2** (Royal College of Physicians, 2012/2017), and ICU severity scores (SOFA, APACHE) — are the clinical ancestors of RAXHA's risk scoring: simple, validated, interpretable aggregations of vital signs into a risk tier that triggers graded escalation. RAXHA's Decision Engine is, in spirit, a *personalized, multimodal, continuously-running early-warning-and-escalation system* — the thing hospitals do at the bedside, done on the wrist.

---

## 3. Scientific Foundation

### 3.1 Context as structured state
Context is not a vector of raw features; it's a *structured situation*: `{who: user + baseline confidence, what: fused state + anomaly candidates, where: semantic place + confidence, when: time/routine, activity: HAR state, coverage: sensor/link health, history: recent events}`. Missing/low-confidence elements are *represented* (Decision #13), never assumed benign.

### 3.2 Risk scoring as decision theory (not classification)
The naive framing ("classify emergency vs not") is wrong because it ignores *costs*. The correct framing: estimate $P(\text{emergency} \mid \text{evidence})$ (calibrated — Decision #18), then act to minimize **expected loss** under an explicit, *asymmetric* cost model:
- **Cost of a missed emergency (false negative):** catastrophic — potentially a life.
- **Cost of a false alarm (false positive):** trust depletion, alarm fatigue, eventually a disabled product (Decision #19) — *and* real costs (needless 911 dispatch, family panic).
These are not symmetric, and they're not even the same *kind* of cost — one is a rare catastrophe, the other a slow erosion. The decision threshold is where expected-loss is minimized given the calibrated probability and these costs — and it is **personalized and context-dependent**: for an 80-year-old living alone at night, the missed-emergency cost is higher and the threshold lower; for a marathoner mid-race, the false-alarm prior is higher and the threshold higher.

### 3.3 Bayesian evidence combination
Risk scoring is Bayesian belief updating (like fusion, C10, but over *the emergency hypothesis*): a prior (this person, this context, this time — most moments are not emergencies, a strong prior against alarm) updated by each piece of evidence weighted by its calibrated reliability. Independent corroborating signals (impact + posture + physiology + immobility) multiply toward confidence; a lone anomaly barely moves the posterior (the base-rate discipline, C1/C11, formalized).

### 3.4 The trust budget as objective function (Decision #19)
Formally: RAXHA maximizes **true help delivered per unit of trust spent**. Each alert has an expected benefit (P(real) × value-of-timely-help) and an expected cost (P(false) × trust-depletion + dispatch cost). Alert only when expected benefit exceeds expected cost *given the current trust balance* — and note trust is *depletable and slowly-refilling*, so a string of false alarms should *raise* the bar (a system that just cried wolf should be more conservative). This is the mathematical form of "don't exhaust human attention."

### 3.5 Graded, confidence-proportional response
The decision is not binary (alert/silent). It's a *graded policy* matched to risk × confidence × consequence:
- **Low risk / benign-explained:** log, update baseline, nothing.
- **Sub-acute / uncertain:** passive observation, maybe a gentle check-in.
- **Moderate risk / responsive user likely:** **countdown** (the user can cancel — the false-alarm control that makes moderate-confidence detection shippable).
- **High risk / unresponsive / high-consequence:** fast alert, short/no countdown.
- **Low measurement confidence + alarming context (Decision #13 corollary):** resolve toward a *low-cost human check* ("are you OK?"), never silence.
The countdown length itself is a decision variable (shorter when risk/consequence is higher).

---

## 4–8. Working, Data, Algorithms (RAXHA-specific)

**The Decision Engine pipeline:**
```
fused state + anomaly candidates + baselines (C10/C11)
  → CONTEXT ASSEMBLY (situation struct: state, place, time, activity, coverage, history)
  → RISK SCORING (calibrated P(emergency|context) + severity, under asymmetric cost model)
  → POLICY (expected-loss-minimizing action, personalized threshold, trust-budget-aware)
  → graded action: none / observe / check-in / countdown / alert / escalate
  → EXPLANATION (why: the evidence, in responder vocabulary — Decision #15)
  → Response Layer (B10)
```

**Algorithms:** the risk score can be a calibrated probabilistic model (Bayesian network, logistic/gradient-boosted model with calibration, or a learned model with a calibration layer) — but **interpretability is a safety requirement** here more than anywhere: the decision to call for help must be explainable to the user, the family, a clinician, and a regulator. A NEWS2-style **interpretable weighted aggregation** of calibrated evidence is often preferable to an opaque deep model at the final decision, even if slightly less accurate — because an unexplainable life-critical decision is not deployable (§11, §12). The policy layer is often explicit rules over the risk score (thresholds, countdowns, escalation ladders) precisely so it's auditable — *deterministic policy over a probabilistic score* (Doctrine #3: deterministic logic + validated ML, never an LLM, in the decision path).

**Personalization (Decision #16):** priors, thresholds, and costs are per-user and per-context (age, living situation, medical profile, time-of-day, armed modes). The *policy* is personalized data, not code (Doctrine — policy is configuration).

**Explainability (XAI, Decision #15):** every decision emits its rationale — "high-impact fall + no movement for 45s + heart rate elevated + at home alone" — in responder vocabulary. This serves the user (cancel decision), the family (respond decision), the clinician (context), and the regulator (auditability).

---

## 9–12. Products, Research, Security, Medical (brief)

**Products:** Apple/Garmin fall & crash detection *are* Decision Engines (multi-signal risk → countdown → SOS), though closed; NEWS2 and clinical early-warning systems are the validated open ancestors; automotive crash decision systems (airbag ECUs) are decision-theoretic safety systems with the same asymmetric-cost structure. **Research:** decision theory, cost-sensitive learning, calibrated risk models, clinical early-warning-score validation, explainable AI for high-stakes decisions, and the alarm-fatigue literature (the empirical study of trust depletion — Decision #19's evidence base). **Open problems:** personalized calibrated risk from multimodal wearable data, learned-but-explainable decision policies, quantified trust-budget models, and prospective real-world validation (the SisFall→FARSEEING honesty check at the decision level). **Security:** the Decision Engine is a high-value attack target (suppress a real alarm, or trigger false ones) → integrity, cross-sensor consistency (C10), tamper-evidence; the decision logic and thresholds are safety-critical config requiring signed, audited updates. **Medical:** this is where screening-vs-diagnosis and regulatory posture bite hardest (Module 16) — a system that *decides* to summon help based on health signals is functionally an emergency-response medical system; claims, validation, and the explainability of decisions are regulatory concerns. Alarm fatigue is the clinically-documented failure mode Decision #19 exists to prevent.

## 13. Engineering for RAXHA

1. **Three clean layers** (context → risk → policy), with the C10/C11 evidence flowing up and only Risk/Policy acting (Decision #17).
2. **Calibrated probabilistic risk + explicit asymmetric cost model** (Decision #18) → expected-loss-minimizing, personalized, context-dependent thresholds.
3. **Deterministic, auditable policy over the probabilistic score** (Doctrine #3): rules for countdown/escalation the user and a regulator can inspect; no LLM in the decision.
4. **Graded, confidence-proportional response** (§3.5), with the countdown as the moderate-confidence false-alarm control and the "are you OK?" check as the low-confidence-alarming-context resolver (Decision #13).
5. **Trust-budget awareness** (Decision #19): recent false alarms raise the bar; the objective is justified interruption, monitored via FA/person-week and acknowledgment rates.
6. **Every decision is explainable** (Decision #15) in responder vocabulary — for user, family, clinician, regulator.
7. **Policy is personalized configuration** (age, living situation, armed modes, quiet hours), changeable without a release.

## 14. Failure Analysis

| Failure | Mechanism | Mitigation |
|---|---|---|
| Alarm fatigue / trust exhausted | Threshold ignores false-alarm cost | Asymmetric cost model; trust-budget-aware threshold (Decision #19) |
| Missed emergency | Threshold too conservative / lone signal | Corroboration; personalized lower threshold for high-consequence contexts |
| Unexplainable alert | Opaque model at the decision | Interpretable risk aggregation + deterministic policy (Doctrine #3) |
| Same threshold for everyone | No personalization | Per-user/context priors, costs, thresholds (Decision #16) |
| Uncalibrated risk → wrong threshold | Score isn't a probability | Calibration (Decision #18) before policy |
| Context silences a real event | Context used as veto | Decision #17 veto contract — context adjusts, never suppresses |
| Binary alert/silent misses nuance | No graded response | Graded policy (observe/check-in/countdown/alert) |
| Cries wolf then cries wolf again | Trust budget ignored | Recent-FA-raises-bar; monitor acknowledgment/FA rates |

## 15. RAXHA Application — distilled

- **Use as:** the judgment layer — the one place that decides to spend a family's trust, doing so on calibrated evidence, personalized cost, graded response, and an auditable explanation.
- **Do NOT use as:** a black box (must be explainable); an accuracy-maximizer (optimize appropriate interruption, Decision #19); a one-size threshold; a place for an LLM (Doctrine #3); a layer that lets context veto (Decision #17).
- **One-liner:** *the Decision Engine is where RAXHA stops perceiving and starts judging — spending trust only when the evidence, the person, and the stakes together justify interrupting someone who loves them.*

## 16. Future

Personalized calibrated multimodal risk models; learned-yet-explainable decision policies; formal trust-budget optimization; prospective clinical validation of the end-to-end decision (Module 16); causal/counterfactual explanations ("we alerted because X; had Y been true we wouldn't have"); adaptive policies that learn each family's response patterns without over-fitting.

## 17. Mastery Test — Competency 12

1. Why is risk scoring a *decision-theoretic* problem, not a classification problem? What does the asymmetric cost model change?
2. Explain the trust budget (Decision #19) as an objective function. Why should a recent string of false alarms make RAXHA *more* conservative?
3. Design the graded, confidence-proportional response policy. When does RAXHA observe vs check-in vs countdown vs alert vs escalate, and how do risk, confidence, and consequence set the countdown length?
4. Why is interpretability a *safety* requirement at the decision layer specifically, and why does that argue for deterministic policy over a probabilistic score (Doctrine #3)?
5. How do personalization (Decision #16) and calibration (Decision #18) enter the threshold, and why must the threshold be context-dependent?
6. Connect NEWS2 (clinical early-warning scores) to RAXHA's risk scoring — what does RAXHA borrow, and what does it add?
7. **[Standing gate question]** If RAXHA shipped its Decision Engine tomorrow, what's the single most likely field failure — scientific, platform, or product?

## 18. Founder Intelligence

**Why hasn't this been "solved"?** The Decision Engine requires *everything below it* done right (the reason it's Competency 12), plus calibrated personalized risk (hard) and prospective validation (slow) and explainability (a constraint that rules out the most accurate opaque models). Apple/Garmin have closed Decision Engines for their scoped features; nobody ships an *open, personalized, explainable, cross-platform* one. **The moat:** the Decision Engine is where all of RAXHA's competencies *integrate into judgment* — and judgment tuned on the real-world outcome flywheel (which alerts were real, which were canceled) is the compounding, uncopyable asset. **WHOOP/Oura** stop at observation (no emergency decision); Apple/Garmin decide but closed and scoped. **Why doesn't everyone build it?** anomaly/base-rate/alarm-fatigue traps punish naïveté; explainability + validation + regulation raise the bar; and it needs the full stack. **Startup opportunities:** the calibrated-risk-and-decision layer as infrastructure; explainable clinical-decision-support; personalized early-warning for elder care. **RAXHA strategy:** the Decision Engine is the *product's judgment* — the thing that makes RAXHA trustworthy rather than noisy; optimize appropriate interruption (Decision #19), keep it explainable and deterministic-policy (Doctrine #3), personalize it, and validate it prospectively before medical claims (Module 16). **PhD gaps:** calibrated personalized multimodal risk, explainable high-stakes policy, formal trust-budget models, prospective decision validation. **Patents:** multi-sensor emergency-decision families (Apple crash/fall — query `multi-sensor emergency detection decision wearable assignee:X`); clinical early-warning-score systems. **Ledger:** ✅ decision theory, NEWS2, alarm-fatigue literature, closed product behaviors; 🟡 vendor decision logic/thresholds; 🔴 outcome-labeled decision datasets.

## 19. Design Review (highlights)

- **Physician:** "This is NEWS2 personalized and continuous — I like it. But show me it's *explainable* (I need to know *why* it alerted) and *validated prospectively* on my population, not retrospectively on lab data."
- **Chief Scientist:** "Show me the risk score is calibrated and the cost model is explicit and asymmetric. A threshold on an uncalibrated score is Decision #18 violated at the most important layer."
- **Investor:** "This is the judgment that makes RAXHA trustworthy vs noisy — the integration moat. Optimizing 'appropriate interruption' is the actual product. How do you measure trust spent?"
- **Regulator (Module 16 preview):** "A system that decides to summon help from health signals is an emergency medical system. Your decision must be explainable, auditable, and validated; your claims must match your evidence."
- **Security researcher:** "The decision logic is the highest-value attack target — suppress or spoof. Signed thresholds, tamper-evidence, cross-sensor integrity."
- **Ethicist:** "Personalized thresholds mean different people get different protection. Justify the fairness of that — is an equitable floor guaranteed?"

## 20. Constraint Exercise

Design RAXHA's Decision Engine for the fall path. Inputs: calibrated fused state + anomaly candidates + baselines + context (place, time, activity, coverage). Constraints: explicit asymmetric cost model, personalized+calibrated context-dependent threshold, graded response (observe→check-in→countdown→alert→escalate) with a risk-dependent countdown, trust-budget awareness (recent FAs raise the bar), deterministic auditable policy (no LLM), and every decision explainable in responder vocabulary. Specify: the context struct, the risk model + calibration, the cost model, the policy rules + thresholds, the explanation output, and the metrics (FA/person-week, acknowledgment rate, missed-event rate, trust proxy). One-page memo.

## 21. Chief Scientist's Verdict

**Confidence Ledger:** Decision-theoretic risk with asymmetric costs — ★★★★★ (sound, clinically precedented). Trust-budget objective (Decision #19) — ★★★★☆ (strong principle; formal models emerging). Interpretable weighted risk aggregation (NEWS2-style) — ★★★★★. Graded confidence-proportional response — ★★★★☆. Calibrated personalized multimodal emergency risk — ★★★☆☆ (**the differentiated, harder build**). Prospectively-validated end-to-end decision — ★★☆☆☆ (needs the trials — Module 16).
**TRL:** Decision theory / early-warning scores — 9. Countdown/graded escalation — 8–9 (shipped by Apple/Garmin, closed). Calibrated personalized multimodal risk — 4–5 (RAXHA's build). Explainable decision — 6–7. Prospectively-validated safety decision — 3–4 (validation gap).
**Roadmap:** *MVP:* interpretable risk aggregation + explicit cost model + graded policy (countdown) + explanations; consume/mirror platform decisions where they exist. *V2:* personalized calibrated risk, trust-budget-aware thresholds, learned-but-explainable models. *Research:* prospective validation, formal trust-budget, causal explanations. *Never Build:* opaque decision models; uncalibrated-score thresholds; one-size thresholds; LLM-in-the-decision (Doctrine #3); context-as-veto (Decision #17).
**Competitor failures (sourced):** clinical alarm fatigue (extensively documented — the empirical proof that over-alerting kills responsiveness; Decision #19's evidence). Apple crash-detection false-911 waves (2022–23, documented — a Decision-Engine cost-model failure: roller-coasters/skiing mis-scored) — even the best-resourced Decision Engine shipped a context-cost error; shadow mode + trust-budget are the defenses. Early-warning-score deployments that failed on poor calibration or alert overload (clinical literature) — the decision layer fails on calibration and alarm-load, exactly RAXHA's Decisions #18/#19.
**Kill Criteria:** if the risk score can't be calibrated and the decision can't be made explainable, do not ship autonomous alerting — keep human-in-the-loop confirmation heavier. If FA/person-week can't meet the trust bar in shadow mode, raise thresholds/add corroboration before enabling. If prospective validation for any *medical* decision claim isn't met, ship as safety/wellness with honest scope (Module 16), never as validated medical decision-making.
**Historical Failures (Historian):** clinical alarm fatigue (the canonical case — monitors ignored, real events missed). Apple crash-detection false alarms (the Decision-Engine cost-model lesson). Automotive false-airbag/false-crash cases (decision systems with mis-tuned costs) — asymmetric-cost decision systems fail visibly and dangerously when the cost model is wrong; explicit, validated, personalized cost models are the defense.

## 22. Knowledge Graph Connections

- **Depends on (prior):** C10 fusion (calibrated state), C11 anomaly (candidates), C5/C8 baselines, C6/C7/C9 context (place/activity), B1 coverage, and Decisions #13/#15/#16/#17/#18/#19 — this layer *is* where most doctrine decisions converge.
- **Depended on by (future):** B10 Response (delivers the decision), Module 16 (validates the decision), the whole product's trustworthiness.
- **RAXHA subsystem:** the Decision Engine (Context → Risk → Policy) — the judgment layer, top of the intelligence graph before Response.
- **AI models:** calibrated probabilistic risk models (Bayesian/GBM+calibration), interpretable weighted aggregation (NEWS2-style); deterministic policy rules over the score (no LLM).
- **Sensors contributing:** all — via the fused state, baselines, anomaly candidates, and context.
- **Assumptions for validity:** calibrated inputs (Decision #18); explicit asymmetric costs; personalized context-dependent thresholds; deterministic auditable explainable policy; trust-budget-aware; context never vetoes (Decision #17).
- **Confidence:** decision-theory foundation ★★★★★ / calibrated personalized emergency risk ★★★ / prospectively-validated decision ★★. See [master graph](../03-KNOWLEDGE-GRAPH.md).

---

*Paired chapter this competency: **B11 — Security Engineering: Keychain/Keystore, E2E Encryption, TEE** — protecting the decision, the data, and the person.*
