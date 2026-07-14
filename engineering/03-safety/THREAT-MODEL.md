# Threat Model — Adversarial Investigation (v0.1, 2026-07-14)

> Investigator-mode desk analysis (the artifact 03-safety always promised, B11 §1 expanded). Organized by **adversary**, not by component — because the most dangerous adversary found is not a hacker. Severity uses the hazard taxonomy (10A): the worst threat class is anything producing **H-01 (missed emergency)** or weaponizing **H-09 (privacy)**. Each finding states: existing control (✅/partial) or **GAP** → feeding the [Evidence Register](../audits/EVIDENCE-REGISTER.md) (E-22…E-25) and RFC candidates.

## Adversary classes

**A — External network attacker · B — Thief with a device · C — Trust-circle insider (family member / caregiver — the adversary the current docs barely model) · D — The wearer (evasion) · E — Vendor/infrastructure compromise · F — Mass abuser (flood/spam)**

---

## Findings (ranked by what they threaten)

### 🔴 T-01 — Coercive control: the monitor is the abuser *(adversary C · threatens H-01 + H-09 · GAP)*
Elder abuse is statistically most often committed by family members and caregivers — **the exact people RAXHA empowers with location, coverage status, and alert control.** If the abuser is the configuring "David": they see her location continuously (incident-only server retention doesn't help — the *app* shows live status), receive every alert, and can structurally suppress help (see T-02). RAXHA as designed authenticates *devices* and *consent to be a contact* — it never verifies the *wearer's* meaningful consent to be monitored, and family-led setup means the wearer may never have chosen any of it.
**Existing controls:** privacy minimization (server-side) ✅ — irrelevant to this threat (the abuse happens through the *legitimate* app surface). Wearer-dignity noted as "minor UX" in AUDIT-001 — **it is not minor; it is a threat class.**
**Needed (RFC candidate — product decision):** a wearer-side **consent ceremony** (on-watch, plain language, at setup and periodically), permanent wearer-visible transparency ("who can see me"), a wearer-initiated revocation path that cannot be silently overridden, and (facility tier) mandated multi-party monitoring. → **E-22.**

### 🔴 T-02 — Alert suppression by an insider *(adversary C · threatens H-01 · partial GAP)*
The lethal attack is not triggering false alerts — it's **preventing real ones**: put the watch on the charger, toggle fall detection off, revoke a permission, keep the phone dead. Coverage Assurance detects all of these ✅ — **but every coverage warning routes to the contacts, and if the sole contact is the suppressor, the control loop is closed by the adversary.**
**Existing controls:** Coverage telemetry + RFC-006's detection-enabled field ✅ detect the suppression. **GAP:** single-contact configurations have no independent observer.
**Needed:** encourage/require ≥2 contacts in different households; surface chronic-suppression patterns distinctly ("protection has been disabled 14 nights running"); facility tier: escalation to an organization, not a person. → **E-23.**

### 🟠 T-03 — SIM swap / stolen responder phone → false acknowledgment *(adversary A/B · threatens H-01)*
The ladder stops on acknowledgment. An SMS-rung ack is authenticated by *possession of a phone number* — exactly what SIM-swap defeats and phone theft borrows. A false ack = escalation halted while nobody helps (a targeted version of H-04's "ack ≠ help").
**Existing controls:** app-based ack is device+account authenticated ✅. **GAP:** SMS/web ack is weak-authenticated.
**Needed (design decision):** treat SMS-ack as **weak-ack** — it pauses but does not terminate the ladder (e.g., requires outcome confirmation within N minutes or escalation resumes); full-stop ack re