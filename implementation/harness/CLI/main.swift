import Foundation
import RaxhaCore
import RaxhaHarnessKit

// raxha-harness — Phase 0 replay harness CLI. A THIN shell over RaxhaHarnessKit.Harness:
// it does argument parsing and file I/O only; all verification logic lives in the library
// so HarnessTests can challenge it directly (AUDIT-002 primary-finding fix).
//   swift run raxha-harness [--corpus <dir>] [--evidence <dir>] [--baseline <file>] [--rebaseline]
// Exit code 0 ONLY on an unambiguous PASS from both rigs — BLOCKED/FAIL are non-zero.

let arguments = CommandLine.arguments
func argValue(_ flag: String, default def: String) -> String {
    if let i = arguments.firstIndex(of: flag), i + 1 < arguments.count { return arguments[i + 1] }
    return def
}
func hasFlag(_ flag: String) -> Bool { arguments.contains(flag) }

let corpusDir = URL(fileURLWithPath: argValue("--corpus", default: "harness/corpus"))
let evidenceDir = URL(fileURLWithPath: argValue("--evidence", default: "harness/evidence"))
let schemaFile = URL(fileURLWithPath: argValue("--contracts", default: "shared/contracts/if-int-objects.schema.json"))
let baselineFile = URL(fileURLWithPath: argValue("--baseline", default: "harness/baseline/golden-hashes.json"))
let rebaseline = hasFlag("--rebaseline")

do {
    let fm = FileManager.default
    let files = (try? fm.contentsOfDirectory(at: corpusDir, includingPropertiesForKeys: nil)) ?? []
    guard files.contains(where: { $0.pathExtension == "json" }) else {
        FileHandle.standardError.write(Data("No traces found in \(corpusDir.path)\n".utf8))
        exit(2)
    }

    #if os(Windows)
    let platform = "windows"
    #elseif os(macOS)
    let platform = "macos"
    #else
    let platform = "linux"
    #endif

    var baseline: [String: String] = [:]
    if let data = try? Data(contentsOf: baselineFile),
       let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
        baseline = decoded
    }

    let outcome = try Harness.execute(
        corpusDir: corpusDir, schemaFile: schemaFile, toolchain: "swift-\(platform)",
        baseline: baseline, rebaseline: rebaseline)

    try fm.createDirectory(at: evidenceDir, withIntermediateDirectories: true)
    try outcome.determinismData.write(to: evidenceDir.appendingPathComponent("VV-101-determinism-report.json"))
    try outcome.contractData.write(to: evidenceDir.appendingPathComponent("VV-110-contract-report.json"))

    if rebaseline {
        try fm.createDirectory(at: baselineFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        let genc = JSONEncoder(); genc.outputFormatting = [.sortedKeys, .prettyPrinted]
        try genc.encode(outcome.golden).write(to: baselineFile)
        print("REBASELINED: wrote \(outcome.golden.count) golden hash(es) to \(baselineFile.path)")
    }

    outcome.lines.forEach { print($0) }
    print("Evidence written to \(evidenceDir.path)")
    exit(outcome.passed ? 0 : 1)
} catch {
    FileHandle.standardError.write(Data("harness error: \(error)\n".utf8))
    exit(2)
}
