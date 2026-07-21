import Foundation
import RaxhaCore

// Public facade over the Phase-0 rigs. The rig internals (Rigs, ReplayRunner, ContractSchemas,
// SchemaValidator, SHA256, Trace) stay `internal` to this library target — the CLI drives them
// through this one entry point, and HarnessTests reaches the internals via `@testable import`.
// This is what lets the verifier finally BE tested: the gate is no longer trapped inside an
// executable target that nothing can depend on (AUDIT-002 primary finding).

public struct HarnessOutcome {
    public let determinismStatus: String
    public let contractStatus: String
    public let lines: [String]
    public let determinismData: Data
    public let contractData: Data
    /// Per-trace decision-log hashes for exercised traces — the value written on --rebaseline.
    public let golden: [String: String]
    /// Green ONLY on an unambiguous PASS from both rigs; BLOCKED/FAIL/NOT-EXECUTED are not success.
    public var passed: Bool { determinismStatus == "PASS" && contractStatus == "PASS" }
}

public enum Harness {
    public static func execute(corpusDir: URL, schemaFile: URL, toolchain: String,
                               baseline: [String: String], rebaseline: Bool) throws -> HarnessOutcome
    {
        let fm = FileManager.default
        let traceFiles = try fm.contentsOfDirectory(at: corpusDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        let decoder = JSONDecoder()
        let traces = try traceFiles.map { try decoder.decode(Trace.self, from: Data(contentsOf: $0)) }

        let determinism = try Rigs.determinism(traces: traces, runs: 3, toolchain: toolchain,
                                               baseline: baseline, rebaseline: rebaseline)
        let contracts = try Rigs.contracts(traces: traces, schemas: try ContractSchemas(schemaFileURL: schemaFile))

        let enc = JSONEncoder(); enc.outputFormatting = [.sortedKeys, .prettyPrinted]
        let detData = try enc.encode(determinism)
        let conData = try enc.encode(contracts)

        var golden: [String: String] = [:]
        for t in determinism.traces where t.logEntries > 0 { golden[t.traceId] = t.hashes.first ?? "" }

        var lines: [String] = []
        lines.append("Loaded \(traces.count) trace(s) from \(corpusDir.path)")
        lines.append("VV-101 determinism: \(determinism.status)  (\(determinism.traces.count) trace(s))")
        for t in determinism.traces {
            let exercised = t.logEntries > 0
            let repeatFlag = !exercised ? "not-exercised (empty log)"
                : (t.identical ? "identical×\(t.runs)" : "DIVERGED")
            lines.append("  \(t.traceId): \(repeatFlag) [\(t.baselineStatus)] \(t.hashes.first ?? "")")
        }
        lines.append("VV-110 contracts:  \(contracts.status)")
        for i in contracts.interfaces {
            lines.append("  \(i.id): \(i.status) (\(i.objectsChecked) objects)")
        }

        return HarnessOutcome(
            determinismStatus: determinism.status, contractStatus: contracts.status,
            lines: lines, determinismData: detData, contractData: conData, golden: golden)
    }
}
