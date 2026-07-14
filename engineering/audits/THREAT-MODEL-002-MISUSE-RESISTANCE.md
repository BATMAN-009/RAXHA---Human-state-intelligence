# THREAT-MODEL-002 — Misuse Resistance (caregiver-as-adversary, broadened)

> **Charter (strict):** this is *threat enumeration*, not architecture. Output is `Observation → Evidence → Impact → Requirement-a-control-must-meet → possible RFC`. It deliberately does **not** design the misuse-resistance subsystem — that is work the founder-approved RFC-007 would spawn. Broadens THREAT-MODEL-001 T-7 from "anti-surveillance" to the full **enrollment → consent → control → exit** lifecycle.
>
> **Prior art (this is not hypothetical):** location-sharing apps, parental-control software, AirTags, and smart-home systems have all been documented as repurposed for stalking and coercive control. A product built to protect the vulnerable is, by construction, a near-optimal tool to control them. The mission ("helps the *right* people") assumes the monitor is benign; a fraction of the time, they are the threat.

---

## The misuse surface

**M-1 — Forced / uninformed enrollment.** *Obs:* the account-owning family member sets up the watch "for safety"; the elder may not understand, consent to, or even know the extent of monitoring. *Evidence:* stalkerware is installed by someone with device access; parental-control patterns. *Impact:* nonconsensual monitoring from day one. *Existing:* onboarding assumes benign family-led setup (compounds H3). **Requirement:** the elder (the *subject*) must pass an informed-consent step in their own comprehension, and must be able to see *that* they are monitored and *by whom* — enrollment cannot be silent to its subject.

**M-2 — Hidden or forced visibility settings.** *Obs:* abuser configures what they can see and conceals it from the elder. *Evidence:* stalkerware's defining trait is hiding itself. *Impact:* covert surveillance. **Requirement:** monitoring settings must be elder-visible and elder-vetoable; no hidden watchers; changes to who-sees-what must be tamper-evident *to the elder*.

**M-3 — Fake / illegitimate caregiver relationship.** *Obs:* someone adds themselves as monitor/contact without a genuine caregiving relationship (new "friend," financial predator). *Evidence:* elder romance/financial-abuse scams. *Impact:* a predator gets presence + location. **Requirement:** adding a monitor/contact requires the elder's own confirmation, not only the requester's action.

**M-4 — Account-control asymmetry (the structural root).** *Obs:* the adult child is account owner + payer + installer; the elder is merely the *subject* with no agency. *Evidence:* joint-account and guardianship coercion. *Impact:* every other misuse vector is enabled by this asymmetry. **Requirement:** the *subject* must be the root of consent, architecturally separable from the *account owner/payer* — the person being watched holds rights the watcher cannot override.

**M-5 — Notification interception / selective suppression.** *Obs:* an abusive contact routes alerts only to themselves, or suppresses alerts to other genuine family. *Evidence:* DV control of a victim's communications. *Impact:* isolation; a real emergency reaches only the controller. **Requirement:** the escalation/contact list must not be single-point-controllable by one contact invisibly to others or to the elder; the elder can see the full responder list.

**M-6 — Coerced non-revocation (locked in).** *Obs:* the elder wants monitoring to stop but can't — the abuser controls the account/password. *Evidence:* documented difficulty of removing stalkerware by victims. *Impact:* inescapable surveillance. **Requirement:** the elder must have a unilateral, low-friction path to review, reduce, or exit monitoring, independent of the account owner.

**M-7 — Weaponized incident history.** *Obs:* abuser fabricates or exaggerates "she fell / wandered / is unsafe" to justify control, guardianship, or institutionalization. *Evidence:* elder-guardianship abuse cases. *Impact:* the product's *records* become an instrument of control. **Requirement:** incident history must be tamper-evident and elder-reviewable, so it cannot be silently fabricated as a coercion narrative.

**M-8 — Account takeover as a misuse enabler.** *Cross-ref:* THREAT-MODEL-001 **T-8** (SIM-swap / Apple ID). Here it's the *insider* variant — a family member who knows the elder's credentials. **Requirement:** subject-side controls (M-1…M-7) must not be defeatable purely by knowing the account password → step-up/authenticated confirmation for subject-affecting changes.

---

## The central tension (surfaced, deliberately NOT resolved here)

**Elder agency vs. the safety mission.** Misuse resistance says *the elder can revoke monitoring*. The safety mission says *a cognitively-declining elder may revoke protection they genuinely need* — and diminished capacity is common in the exact population. These two goods conflict, and the conflict is **not an engineering question** — it is an ethics + legal (capacity, guardianship law, jurisdiction) + possibly clinical question. Resolving it inside an RFC without that expertise would be malpractice.

→ **This is the load-bearing decision inside RFC-007, and it belongs to the founder + qualified counsel, not to me.** The investigator's job ends at *"here is the tension, here is why it's hard, here is who must decide it."*

---

## Possible scope for RFC-007 (a requirements list, NOT a design)

If accepted, RFC-007 must produce controls satisfying M-1…M-8 above, and must explicitly decide the agency-vs-capacity tension with ethics/legal input before any beta with real elders. Partial control already present: D21 minimization (family gets incident-time location only, never continuous tracking) covers the continuous-surveillance leg of M-2 — *reframed as a misuse-resistance guarantee, not merely privacy.* Everything else (M-1, M-3, M-4, M-6, M-7, M-8, and the tension) is new work the RFC would authorize.

*Logged as a Notebook-A-class discovery: reality — the human threat model — arguing before code. No architecture proposed; evidence and requirements only.*
