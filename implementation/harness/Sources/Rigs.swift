import Foundation
import RaxhaCore

// The two Phase-0 exit-gate rigs (Roadmap 14 Part B):
//   VV-101 determinism rig — identical traces ⇒ bit-identical decisions (SRS-402, ADR-104/109)
//   VV-110 contract rig    — IF-* objects honor contract version + failure semantics (12)
// Each produces an evidence artifact (13: every VV item has an Evidence Package).
// Statuses use the 13 taxonomy: PASS / FAIL / BLOCKED / NOT-EXECUTED — "completed" is not a status.

struct DeterminismTraceResult: Codable {
    var traceId: String
    var runs: Int
    var hashes: [String]
    var identical: Bool
    var logEntries: Int          // 0 ⇒ nothing was exercised (NOT a determinism pass)
    var baselineHash: String?    // committed golden hash, if any
    var baselineStatus: String   // MATCH | CHANGED | NO_BASELINE | REBASELINED
}

struct DeterminismReport: Codable {
    var vv: String = "VV-101"
    var evidencePackage: String = "determinism report (hash comparison)"
    var runAt: String
    var toolchain: String
    var traces: [DeterminismTraceResult]
    var status: String // PASS | FAIL | BLOCKED | NOT-EXECUTED
    var note: String
}

struct InterfaceReport: Codable {
    var id: String
    var contractVersion: String
    var status: String // CONFORMS | VIOLATIONS | NOT_EXERCISED
    var objectsChecked: Int
    var violations: [SchemaViolation]
    var notes: String?
}

struct ContractReport: Codable {
    var vv: String = "VV-110"
    var evidencePackage: String = "contract test report"
    var runAt: String
    var interfaces: [InterfaceReport]
    var status: String // PASS (exercised subset) | FAIL
    var note: String
}

enum Rigs {

    /// VV-101. `runs` MUST be ≥ 2 — one run cannot demonstrate repeatability. A golden
    /// `baseline` (traceId → committed hash) turns "repeatable" into "repeatable AND unchanged":
    /// any decision-path change flips a trace to CHANGED and the rig to FAIL, unless `rebaseline`
    /// is set (a deliberate act). A trace whose decision log is empty is NOT-EXERCISED, never a
    /// silent PASS (the hash of "[]" proves nothing).
    static func determinism(traces: [Trace], runs: Int = 3, toolchain: String,
                            baseline: [String: String] = [:], rebaseline: Bool = false) throws -> DeterminismReport
    {
        precondition(runs >= 2, "determinism needs ≥2 runs to mean anything")
        var results: [DeterminismTraceResult] = []
        for trace in traces {
            var hashes: [String] = []
            var entries = 0
            for _ in 0..<runs {
                let result = try ReplayRunner.run(trace)
                entries = result.log.count
                hashes.append(SHA256.hexDigest(of: try ReplayRunner.canonicalLogData(result)))
            }
            let identical = Set(hashes).count == 1
            let hash = hashes.first ?? ""
            let expected = baseline[trace.traceId]
            let baselineStatus: String
            if rebaseline { baselineStatus = "REBASELINED" }
            else if expected == nil { baselineStatus = "NO_BASELINE" }
            else if expected == hash { baselineStatus = "MATCH" }
            else { baselineStatus = "CHANGED" }
            results.append(DeterminismTraceResult(
                traceId: trace.traceId, runs: runs, hashes: hashes, identical: identical,
                logEntries: entries, baselineHash: expected, baselineStatus: baselineStatus))
        }

        let exercised = results.filter { $0.logEntries > 0 }
        let anyNonIdentical = exercised.contains { !$0.identical }
        let anyChanged = exercised.contains { $0.baselineStatus == "CHANGED" }
        let anyMissingBaseline = !rebaseline && exercised.contains { $0.baselineStatus == "NO_BASELINE" }

        let status: String
        var note: String
        if results.isEmpty {
            status = "NOT-EXECUTED"; note = "No traces supplied."
        } else if exercised.isEmpty {
            // e.g. a vacuous corpus that produces no decisions — determinism of nothing is meaningless.
            status = "BLOCKED"
            note = "No trace produced a non-empty decision log; there is nothing whose determinism can be asserted."
        } else if anyNonIdentical {
            status = "FAIL"; note = "At least one exercised trace was non-identical across \(runs) runs — the decision path is nondeterministic."
        } else if anyChanged {
            status = "FAIL"; note = "At least one trace's decision-log hash differs from the committed golden baseline. If this change is intended, re-run with --rebaseline to update baseline/golden-hashes.json deliberately."
        } else if anyMissingBaseline {
            status = "BLOCKED"; note = "An exercised trace has no committed golden baseline; VV-101 cannot certify it is unchanged. Run --rebaseline once to establish the baseline."
        } else {
            status = "PASS"; note = "All \(exercised.count) exercised trace(s) are identical across \(runs) runs and match the committed golden baseline (SRS-402, ADR-104/109)."
        }
        return DeterminismReport(
            runAt: ISO8601DateFormatter().string(from: Date()),
            toolchain: toolchain, traces: results, status: status, note: note)
    }

    static func contracts(traces: [Trace], schemas: ContractSchemas) throws -> ContractReport {
        var evidenceViolations: [SchemaViolation] = []
        var stateViolations: [SchemaViolation] = []
        var riskViolations: [SchemaViolation] = []
        var decisionViolations: [SchemaViolation] = []
        var journalViolations: [SchemaViolation] = []
        var counts = [String: Int]()

        // Legal FSM edges per Blueprint A6 — journal records must never show any other move.
        let legalEdges: Set<String> = [
            "IDLE>SUSPECTED", "SUSPECTED>IDLE", "SUSPECTED>COUNTDOWN", "COUNTDOWN>IDLE",
            "COUNTDOWN>ALERTING", "ALERTING>ACKNOWLEDGED", "ALERTING>ESCALATING",
            "ACKNOWLEDGED>RESOLVED", "ESCALATING>RESOLVED",
        ]

        for trace in traces {
            let result = try ReplayRunner.run(trace)

            // IF-INT-01 — SensorEvidence v1, best-effort + explicit gap markers.
            for e in result.evidence {
                evidenceViolations += try schemas.validate(e, against: "SensorEvidence")
                if e.receivedAt.monotonicMs < e.measuredAt.monotonicMs {
                    evidenceViolations.append(SchemaViolation(
                        path: "\(trace.traceId)/\(e.id)", message: "receivedAt before measuredAt"))
                }
            }
            counts["IF-INT-01", default: 0] += result.evidence.count

            // IF-INT-02 — HumanState v1, latest-value.
            for s in result.humanStates {
                stateViolations += try schemas.validate(s, against: "HumanState")
            }
            counts["IF-INT-02", default: 0] += result.humanStates.count

            // IF-INT-03 — RiskScore v1; version stamps mandatory (SRS-302, schema minLength).
            for r in result.risks {
                riskViolations += try schemas.validate(r, against: "RiskScore")
            }
            counts["IF-INT-03", default: 0] += result.risks.count

            // IF-INT-04 — PolicyDecision v1, exactly-once-effect: ids unique; countdown carries seconds.
            var seenDecisionIds = Set<UUID>()
            for d in result.decisions {
                decisionViolations += try schemas.validate(d, against: "PolicyDecision")
                if !seenDecisionIds.insert(d.id).inserted {
                    decisionViolations.append(SchemaViolation(
                        path: "\(trace.traceId)/\(d.id)", message: "duplicate PolicyDecision id (breaks exactly-once-effect)"))
                }
                if d.action == .countdown && d.countdownSeconds == nil {
                    decisionViolations.append(SchemaViolation(
                        path: "\(trace.traceId)/\(d.id)", message: "countdown decision without countdownSeconds"))
                }
            }
            counts["IF-INT-04", default: 0] += result.decisions.count

            // IF-INT-05 — journal + Incident/EscalationState (12 line 23: contract object is
            // "Incident v1 + EscalationState v1", not just the journal records).
            var lastSeq = 0
            for rec in result.journal {
                journalViolations += try schemas.validate(rec, against: "TransitionRecord")
                if rec.seq != lastSeq + 1 {
                    journalViolations.append(SchemaViolation(
                        path: "\(trace.traceId)/seq\(rec.seq)", message: "journal seq not contiguous (write-ahead gap)"))
                }
                lastSeq = rec.seq
                let edge = "\(rec.from.rawValue)>\(rec.to.rawValue)"
                if !legalEdges.contains(edge) {
                    journalViolations.append(SchemaViolation(
                        path: "\(trace.traceId)/seq\(rec.seq)", message: "illegal FSM edge \(edge) (Blueprint A6)"))
                }
            }
            for inc in result.incidents {
                journalViolations += try schemas.validate(inc, against: "Incident")
            }
            journalViolations += try schemas.validate(result.finalEscalation, against: "EscalationState")
            // Count only genuine IF-INT-05 activity (journal records + incidents); the trivial
            // final IDLE state is validated but not counted, so a fall-free corpus honestly
            // reports IF-INT-05 as NOT_EXERCISED rather than manufacturing conformance.
            counts["IF-INT-05", default: 0] += result.journal.count + result.incidents.count
        }

        // Per-interface status: VIOLATIONS beats NOT_EXERCISED beats CONFORMS. An interface
        // that was SUPPOSED to carry objects but carried zero is NOT_EXERCISED, never CONFORMS —
        // absence of evidence is not conformance (the vacuous-gate fix, AUDIT-002).
        func report(_ id: String, _ violations: [SchemaViolation], notes: String? = nil) -> InterfaceReport {
            let n = counts[id] ?? 0
            let status: String
            if !violations.isEmpty { status = "VIOLATIONS" }
            else if n == 0 { status = "NOT_EXERCISED" }
            else { status = "CONFORMS" }
            return InterfaceReport(id: id, contractVersion: "v1", status: status,
                                   objectsChecked: n, violations: violations, notes: notes)
        }

        // The Phase-0 exit gate covers exactly the five internal interfaces (14 Part B). Each MUST
        // be exercised by a real corpus; the remaining 14 interfaces have no producer yet and are
        // honestly NOT_EXERCISED — they do NOT count toward PASS, and they are NOT hidden.
        let required = [
            report("IF-INT-01", evidenceViolations),
            report("IF-INT-02", stateViolations),
            report("IF-INT-03", riskViolations),
            report("IF-INT-04", decisionViolations),
            report("IF-INT-05", journalViolations),
        ]
        let deferred = [
            InterfaceReport(id: "IF-INT-06", contractVersion: "v1", status: "NOT_EXERCISED",
                            objectsChecked: 0, violations: [],
                            notes: "Coverage Monitor arrives in its own phase; no producer exists yet (14 Part B)."),
            InterfaceReport(id: "IF-PLT-*/IF-NET-*/IF-HUM-*", contractVersion: "per 12", status: "NOT_EXERCISED",
                            objectsChecked: 0, violations: [],
                            notes: "Platform, network, and human interfaces gain producers in Phases 1–7 (14 Part B)."),
        ]
        let interfaces = required + deferred

        // Doc-13 taxonomy (PASS/FAIL/BLOCKED/NOT-EXECUTED), scoped to the Phase-0-required set:
        //   FAIL    — any required interface has VIOLATIONS
        //   BLOCKED — any required interface was NOT_EXERCISED (a corpus that certifies nothing)
        //   PASS    — all five required interfaces CONFORM on real objects; deferred stay NOT_EXERCISED
        let anyViolation = required.contains { $0.status == "VIOLATIONS" }
        let anyRequiredNotExercised = required.contains { $0.status == "NOT_EXERCISED" }
        let status: String
        let note: String
        if anyViolation {
            status = "FAIL"
            note = "At least one Phase-0-required interface (IF-INT-01…05) has contract violations."
        } else if anyRequiredNotExercised {
            let empties = required.filter { $0.status == "NOT_EXERCISED" }.map(\.id).joined(separator: ", ")
            status = "BLOCKED"
            note = "The corpus did not exercise every Phase-0-required interface — no objects crossed \(empties). "
                + "A gate that certifies un-exercised interfaces proves nothing; supply a corpus that drives all of IF-INT-01…05 (AUDIT-002 vacuous-gate fix)."
        } else {
            status = "PASS"
            note = "All five Phase-0-required interfaces (IF-INT-01…05) conform on real objects (Interface Spec 12). "
                + "The other 14 interfaces are NOT_EXERCISED by design — no producer exists until later phases (14 Part B); they are reported, not hidden."
        }
        return ContractReport(
            runAt: ISO8601DateFormatter().string(from: Date()),
            interfaces: interfaces, status: status, note: note)
    }
}
