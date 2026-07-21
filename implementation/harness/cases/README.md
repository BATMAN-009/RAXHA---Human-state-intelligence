# CaseKit — the laboratory's case-file registry (VVE-001 Phase I)

> A **case** is a permanent, executable experiment. Its input is a corpus trace (replayable, deterministic); its meaning is machine-readable ground truth and reviewed expectations; its memory is a pinned regression hash. Cases are how the laboratory learns: every production defect, hardware divergence, and field incident becomes a case, forever.

## Binding rules (founder execution charter, 2026-07-21)

1. **Permanent identity.** `CASE-NNNNNN` is issued once and never reused, renamed, or deleted. A fixed bug flips status `KNOWN_DEFICIENT → PASS`; the case's identity, history, linked RFCs, and evidence remain intact.
2. **Two expectations, never blurred.**
   - `groundTruth` — what actually/canonically happened (the world's answer).
   - `expected` — what the system SHOULD do, **derived from SRS/hazard controls/doctrine**, never invented per-case.
   - `pinnedBehavior` — what the current verified system DOES (golden hash). A case may match its pin and still fail ground truth: that is **`KNOWN_DEFICIENT`** — legal, visible, linked to its fix item. Never laundered.
3. **Expectation changes are reviewed like code.** `expected.version` increments only via PR review with a stated reason (claims-under-configuration-control, C15 gate-record artifact 9). Editing an expectation to make a dashboard green is the AUDIT-002 disease; the review exists to catch it.
4. **Provenance is machine-labeled**: `SIMULATED` · `REPLAY_DERIVED` · `HARDWARE_VALIDATED` (+ `SIMULATOR_APPLE` for Apple-Simulator SDK-integration evidence — above port-level simulation, below hardware). Unlabeled cases are invalid.
5. **Honest statuses only**: `PASS` · `KNOWN_DEFICIENT` · `REGRESSION` · `BLOCKED` · `NOT_EXECUTED`. "Completed" is not a status.

## Current state (I1, commit 1)

- `case.schema.json` — case-v0.1 schema.
- `CASE-000001…000006` — migrated from the 6-trace corpus. Their **pins** are live (VV-101 golden hashes, MATCH as of this commit's lineage); their **ground-truth adjudication is `NOT_EXECUTED`** because the CaseKit runner (Swift, next commit) does not exist yet. That is the truthful state: the laboratory does not claim adjudications its instrument cannot yet perform.

## Phase I acceptance criteria (charter) — status

| Criterion | Status |
|---|---|
| Case schema + ground-truth + pinned-behavior models | schema landed (this commit); Swift models = runner commit |
| `KNOWN_DEFICIENT` status | in schema + rules |
| Provenance classes | in schema + rules |
| Regression hash | wired to existing golden-hash baseline |
| Review workflow | rule 3 above; CI enforcement lands with the runner |
| CASE-000001…000006 migrated | **done** |
| New case addable without engine change | cases are data; runner discovers the directory |
| Expectations versioned + review-gated | `expected.version` + rule 3 |

## Phases II–VI (charter, for reference)

II ScenarioKit (scenarios are code) → III virtual device layer at the **port** boundary + VV-111 byte-identical gate → IV laboratory console (mission control for engineers: diagnosis over beauty) → V Guardian World (pipeline incomplete until human behavior is exercised) → VI Arrival Day (one report: input diffs / logic diffs / timing diffs / coverage diffs / new hardware evidence / required RFC updates — **logic differences are defects; input differences are evidence; never confuse the two**).

**Doctrine:** the laboratory does not exist to prove RAXHA works; it exists to discover why it doesn't. A laboratory that only produces passing tests is not doing its job. The laboratory, the corpus, and the evidence grow monotonically. Confidence is earned — not assumed.

**Founder exit criterion:** when the first physical watch arrives, the first instinct is not to code — it is to run the laboratory, compare the witness to the prediction, and let the evidence decide what changes.
