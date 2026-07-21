# AUDIT-002 — Phase 0 Verification Audit (INTERIM)

> **⟳ POST-REPAIR UPDATE (2026-07-15).** Primary Finding **REPAIRED** (local commit `0686617`): verifier extracted to a testable library + thin CLI; 10 adversarial `HarnessTests` (rig now provably rejects vacuous corpus / baseline drift / corrupted objects); truthful PASS/BLOCKED/NOT-EXECUTED taxonomy (vacuous corpus BLOCKs, exit 1); IF-INT-05 validates real `Incident`; committed golden-hash baseline; stable same-timestamp sort. Secondary Finding: **2 of 3 fixed** — `isExpired` monotonic-only (H-02 early-fire) + `Timestamp` saturating add (overflow), both **behavior-preserving** (golden baseline held `MATCH`, no rebaseline needed); validator hardened (null-required + additionalProperties). The **RTC-reset / reboot-recovery** bug is **NOT hacked** — it needs a persisted boot-session id → **[RFC-008](../rfcs/RFC-REGISTER.md)** + [Notebook-A A-01](../../implementation/NOTEBOOK-A-ASSUMPTIONS-DISPROVEN.md); interim: `recover()` fails toward alerting. All 24 unit tests + both rigs green.
>
> **Status: INTERIM.** Produced 2026-07-15 from a 14-dimension adversarial falsification campaign (multi-agent; every candidate finding independently reproduced by one lens and ruled for material impact by a second). Falsification phase complete; ~51 of 122 findings carry both verdicts; the completeness-critic pass did not run. This document records what is already established with evidence. Trigger (four-trigger rule): **Reality/Evidence** — the implementation produced defects that the existing verification could not see. Sibling of [AUDIT-001](AUDIT-001-PRE-PHASE0-PRODUCT-REVIEW.md); lives in the living `audits/` tier, amends no frozen document.

---

## Primary Finding (this is the audit)

> **The Phase-0 verification system is not falsifiable. It can report PASS while proving nothing — therefore every green gate produced so far carries reduced confidence until the verifier is repaired and re-run.**

Everything else in this document is secondary to that sentence. The deeper framing: **the verifier had never been independently challenged** — no test ever fed it input it was supposed to reject, so its passing told us the code under test was consistent with itself, not that it was correct. Reproduced, CONFIRMED at CRITICAL/HIGH by both verification lenses:

- **Vacuous gate.** An empty corpus (one `tick`, zero evidence) makes all five internal interfaces report `CONFORMS` with `objectsChecked = 0`, and the harness exits `0`. Absence of evidence is certified as conformance. `harness/Sources/Rigs.swift:142`.
- **The verifier has no independent challenge.** No test target depends on the rigs. Proven by mutation: inserting `return []` at the top of `SchemaValidator.validate` silently disables the *entire* VV-110 schema gate (still `PASS`, still full object counts); `pass = true` in the determinism rig, or a constant `SHA256`, leaves VV-101 `PASS` with genuine nondeterminism injected. Six of seven single-line rig mutations survive the whole gate.
- **Phantom conformance.** IF-INT-05 reports `CONFORMS`, but its declared contract object `Incident` has **no schema definition and is never validated** — the rig checks `TransitionRecord` only.
- **Overclaimed PASS.** VV-110 reports top-level `PASS` while 14 of 19 interfaces are `NOT_EXERCISED`; per doc-13's own taxonomy that is `BLOCKED`/`NOT-EXECUTED`, not `PASS`. VV-101 reports `PASS` on an empty decision log — the "bit-identical" hash is literally SHA-256 of `"[]"`.

**Consequence if we fix nothing here:** every future regression becomes invisible; all future evidence is weakened; the Phase-0 exit gate certifies nothing. This is the one class that must be repaired *before* anything else, because it is the instrument by which everything else is judged. **Calibrate the instrument before trusting its measurements.**

---

## Secondary Finding — real correctness bugs in existing code (deferred until the verifier is trustworthy)

These are genuine, reproduced defects in shipped `core`/`harness` code. They are **not** touched until the verifier is repaired and re-run — fixing them first would be measuring with a broken instrument.

- **Premature deadline expiry** (`core/fsm/EscalationFSM.swift`) — `transition()` accepts a `deadlineExpired` before the deadline; a forward wall-clock jump (NTP/DST) fires a live countdown early → H-02 false dispatch. CONFIRMED/HIGH.
- **Unstable same-timestamp ordering** (`harness/Sources/Replay.swift:57`) — two events sharing a `monotonicMs` are ordered by an unstable sort; the outcome (wearer-cancel honored vs. family alerted) and the hash depend on an unspecified tie-break. CONFIRMED/MEDIUM–HIGH. *(This one is reclassified as a verifier repair — a golden baseline cannot be trustworthy on top of a nondeterministic sort.)*
- **Int64 overflow** (`core/domain/Timestamp.swift:22`) — `adding(milliseconds:)` traps the process on a schema-valid trace. CONFIRMED/MEDIUM.
- **RTC-reset never-expires** (`core/fsm/EscalationFSM.swift:75`) — on a dead-RTC reboot (wall resets to ~1970, monotonic resets too), a large persisted deadline passes *neither* leg of `isExpired`, so a countdown that expired while the device was dead never fires. Real latent logic gap; only unreachable today because recovery isn't wired. Needs a final ruling; fix defensively.
- **SchemaValidator holes** — a `null` required field passes (NSNull ≠ nil); enum/minLength enforced only on strings; no `additionalProperties`; array item-types unchecked. CONFIRMED/LOW–INFO.

---

## Confidence table

| Finding | Class | Confidence | Disposition |
|---|---|---|---|
| Vacuous gate certifies empty corpus | Verifier | **Very High** | Fix now |
| Rig mutations survive (no independent challenge) | Verifier | **Very High** | Fix now |
| IF-INT-05 phantom conformance (Incident unvalidated) | Verifier | **Very High** | Fix now |
| VV-110 PASS while 14/19 NOT_EXERCISED (taxonomy) | Verifier | **High** | Fix now |
| VV-101 PASS on empty decision log | Verifier | **High** | Fix now |
| Unstable same-timestamp sort | Verifier/Replay | **High** | Fix now (baseline prerequisite) |
| Premature deadline / forward-jump early fire | Implementation | **High** | Step 4 (after verifier) |
| Int64 overflow traps process | Implementation | **High** | Step 4 |
| RTC-reset never-expires | Implementation | **Medium** | Step 4 (final ruling) |
| SchemaValidator gaps (null/enum/array/extra) | Verifier | **High** | Fix now (part of rig repair) |
| Threshold-veto / policy stub, crash-recovery unwired, unconsumed actions, cold-start | Stub scope | **By Design** | No action (documented Phase-0 scope) |

---

## Cost-to-fix (execution, not danger)

| Repair | Effort | Class |
|---|---|---|
| Truthful PASS/BLOCKED/NOT-EXECUTED + min-objects (vacuous gate) | ~1–2 h | Verifier |
| Stable same-timestamp sort | ~20 min | Verifier |
| IF-INT-05 Incident/EscalationState schema + validation | ~1 h | Verifier |
| Committed golden-hash baseline + VV-101 compare | ~2 h | Verifier |
| HarnessTests target (adversarial challenge of the rigs) | ~half day | Verifier |
| Deadline dual-clock + Int64 overflow + RTC-reset | ~2–4 h | Implementation (step 4) |

---

## Execution dependency graph (the order is not a preference — it is forced)

```
Freeze current evidence (rename phase0-gate → phase0-gate-PRE-AUDIT002)
        ↓
Repair the verifier ── stable sort ──┐
   truthful statuses / vacuous gate   ├─→ Golden baseline (needs a deterministic sort under it)
   IF-INT-05 real validation ─────────┘        ↓
                                          HarnessTests (adversarially challenge the repaired rig)
                                                ↓
                                    Re-run the verifier until it FAILS on tampered input
                                       and PASSES honestly on the real corpus
                                                ↓
                                    Only now: fix the implementation bugs (step 4)
                                       — the baseline will flag each fix as a change,
                                         re-baseline deliberately (the mechanism working)
                                                ↓
                                          Resume Phase 0 development
```

---

## The funnel (why the raw counts do not panic us)

```
122 candidate findings   (pre-verification: 15 CRITICAL / 40 HIGH / 33 MEDIUM / 19 LOW / 15 INFO)
        ↓  two independent lenses (reproduce + material-impact)
102 verdicts banked      → 38 CONFIRMED · 63 BY_DESIGN · 1 REFUTED
        ↓  drop LOW/INFO noise, collapse duplicates
~15 materially-actionable findings
        ↓  cluster by root cause
2 stories  →  1 critical (the verifier is not falsifiable)
```

Adversarial verification behaved exactly as designed: the frightening pre-verification count deflated to a small, clustered, actionable set.

## What deflated to BY_DESIGN (the 63) — documented Phase-0 scope, not bugs

The threshold-veto (low-confidence fall → `check_in`); crash-recovery not wired; `.checkIn`/`.observe`/`.alert`/`.escalate` unconsumed; no idempotent consumers; cold-start calibration; the FSM's terminal states — all faithful to Blueprint A6 and the phased roadmap (`RiskEngineV0`/`PolicyEngineV0` are declared stubs; VV-102 veto suite is a Phase-4 gate; RFC-003 is undecided). Several verdicts flagged these as *positive* structural verifications.

## What is still pending

- ~71 findings lack both verdicts (mostly the LOW/INFO tail and domain-fidelity nits).
- The completeness-critic pass ("what did nobody audit?") did not run.
- The RTC-reset never-expires case needs a final CONFIRMED/BY_DESIGN ruling.

## Architectural note

Every actionable finding is an **implementation** defect (verifier code + core logic). **None** touches a frozen document, and none pre-empts a pending RFC. The frozen architecture (Blueprint A6, 08B, the doctrine) survived the audit intact — a healthy result. The project's limiting factor has moved from *architecture* to *evidence quality*, which is exactly where a safety-critical system should be before field deployment.

---

*Next: repair the verifier (this document's Primary Finding), re-run until it fails on tampered input, then fix the Secondary-Finding implementation bugs. This audit is re-issued as FINAL once the pending verifications and the completeness critic complete.*
