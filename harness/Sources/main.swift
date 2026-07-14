import Foundation
import RaxhaCore

// raxha-harness — Phase 0 replay harness CLI.
//   swift run raxha-harness [--corpus <dir>] [--evidence <dir>]
// Loads every *.json trace in the corpus, runs the VV-101 and VV-110 rigs, and writes
// evidence artifacts. Exit code 0 only if both rigs report PASS — CI-as-evidence (B14).

let arguments = CommandLine.arguments
func argValue(_ flag: String, default def: String) -> String {
    if let i = arguments.firstIndex(of: flag), i + 1 < arguments.count {
        return arguments[i + 1]
    }
    return def
}

let corpusDir = URL(fileURLWithPath: argValue("--corpus", default: "harness/corpus"))
let evidenceDir = URL(fileURLWithPath: argValue("--evidence", default: "harness/evidence"))
let schemaFile = URL(fileURLWithPath: argValue(
    "--contracts", default: "shared/contracts/if-int-objects.schema.json"))

do {
    let fm = FileManager.default
    let traceFiles = try fm.contentsOfDirectory(at: corpusDir, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

    guard !traceFiles.isEmpty else {
        FileHandle.standardError.write(Data("No traces found in \(corpusDir.path)\n".utf8))
        exit(2)
    }

    let decoder = JSONDecoder()
    let traces = try traceFiles.map { try decoder.decode(Trace.self, from: Data(contentsOf: $0)) }
    print("Loaded \(traces.count) trace(s) from \(corpusDir.path)")

    #if os(Windows)
    let platform = "windows"
    #elseif os(macOS)
    let platform = "macos"
    #else
    let platform = "linux"
    #endif
    let toolchain = "swift-\(platform)"

    let determinism = try Rigs.determinism(traces: traces, runs: 3, toolchain: toolchain)
    let contracts = try Rigs.contracts(traces: traces, schemas: ContractSchemas(schemaFileURL: schemaFile))

    try fm.createDirectory(at: evidenceDir, withIntermediateDirectories: true)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    try encoder.encode(determinism).write(to: evidenceDir.appendingPathComponent("VV-101-determinism-report.json"))
    try encoder.encode(contracts).write(to: evidenceDir.appendingPathComponent("VV-110-contract-report.json"))

    print("VV-101 determinism: \(determinism.status)  (\(determinism.traces.count) traces × \(determinism.traces.first?.runs ?? 0) runs)")
    for t in determinism.traces {
        print("  \(t.traceId): \(t.identical ? "bit-identical" : "DIVERGED") \(t.hashes.first ?? "")")
    }
    print("VV-110 contracts:  \(contracts.status)")
    for i in contracts.interfaces {
        print("  \(i.id): \(i.status) (\(i.objectsChecked) objects)")
    }
    print("Evidence written to \(evidenceDir.path)")

    exit(determinism.status == "PASS" && contracts.status == "PASS" ? 0 : 1)
} catch {
    FileHandle.standardError.write(Data("harness error: \(error)\n".utf8))
    exit(2)
}
