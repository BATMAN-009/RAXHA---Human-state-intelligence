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
}

struct DeterminismReport: Codable {
    var vv: String = "VV-101"
    var evidencePackage: String = "determinism report (hash comparison)"
    var runAt: String
    var toolchain: String
    var traces: [DeterminismTraceResult]
    var status: String // PASS | FAIL
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

    static func determinism(traces: [Trace], runs: Int = 3, toolchain: String) throws -> DeterminismReport {
        var results: [DeterminismTraceResult] = []
        for trace in traces {
            var hashes: [String] = []
            for _ in 0..<runs {
                let result = try ReplayRunner.run(trace)
                hashes.append(SHA256.hexDigest(of: try ReplayRunner.canonicalLogData(result)))
            }
            let identical = Set(hashes).count == 1
            results.append(DeterminismTraceResult(traceId: trace.traceId, runs: runs,
                                                  hashes: hashes, identical: identical))
        }
        let pass = results.allSatisfy(\.identical) && !results.isEmpty
        return DeterminismReport(
            runAt: ISO8601DateFormatter().string(from: Date()),
            toolchain: toolchain,
            traces: results,
            status: pass ? "PASS" : "FAIL",
            note: "Phase-0 scope: same-machine repeatability across \(runs) fresh runs per trace. "
                + "Cross-platform bit-identity (macOS vs Windows CI) is asserted once CI has both runners.")
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

            // IF-INT-05 — journal: write-ahead durable records, seq strictly increasing, legal edges only.
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
            counts["IF-INT-05", default: 0] += result.journal.count
        }

        func report(_ id: String, _ violations: [SchemaViolation], notes: String? = nil) -> InterfaceReport {
            InterfaceReport(id: id, contractVersion: "v1",
                            status: violations.isEmpty ? "CONFORMS" : "VIOLATIONS",
                            objectsChecked: counts[id] ?? 0, violations: violations, notes: notes)
        }

        var interfaces = [
            report("IF-INT-01", evidenceViolations),
            report("IF-INT-02", stateViolations),
            report("IF-INT-03", riskViolations),
            report("IF-INT-04", decisionViolations),
            report("IF-INT-05", journalViolations),
            InterfaceReport(id: "IF-INT-06", contractVersion: "v1", status: "NOT_EXERCISED",
                            objectsChecked: 0, violations: [],
                            notes: "Coverage Monitor arrives in its own phase; no producer exists yet."),
        ]
        interfaces.append(InterfaceReport(
            id: "IF-PLT-*/IF-NET-*/IF-HUM-*", contractVersion: "per 12", status: "NOT_EXERCISED",
            objectsChecked: 0, violations: [],
            notes: "Platform, network, and human interfaces gain producers/consumers in Phases 1–7; the rig extends per phase (14 Part B)."))

        let exercisedAllConform = interfaces
            .filter { $0.status != "NOT_EXERCISED" }
            .allSatisfy { $0.status == "CONFORMS" }
        return ContractReport(
            runAt: ISO8601DateFormatter().string(from: Date()),
            interfaces: interfaces,
            status: exercisedAllConform ? "PASS" : "FAIL",
            note: "Phase-0 scope per 14 Part B: rig operational, internal interfaces IF-INT-01…05 exercised. "
                + "Full 19-interface conformance (13 exit criterion) accrues as later phases bring producers to life.")
    }
}
