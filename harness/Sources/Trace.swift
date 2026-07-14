import Foundation
import RaxhaCore

// Trace format (trace-v0.1) — the replay corpus unit. Every trace is fully explicit:
// all timestamps, all IDs, all evidence come from the file, so a replay has NO ambient
// inputs (ADR-109). Corpus status: synthetic, manually curated — that is TD-4, expiring
// at Shadow exit.

struct TraceEvent: Codable {
    var at: Timestamp
    /// Present for evidence events (IF-INT-01 objects, verbatim).
    var evidence: SensorEvidence?
    /// Present for human/scheduler events: "wearerCancel" | "contactAck" | "resolveContactAck" | "tick".
    var action: String?
}

struct Trace: Codable {
    var schemaVersion: String
    var traceId: String
    var description: String
    var wearerId: UUID
    var events: [TraceEvent]
}

/// Deterministic IdSource: UUIDs derived from (traceId, counter). Identical trace ⇒
/// identical IDs ⇒ hashable decision logs (VV-101). Version/variant nibbles kept valid.
struct DeterministicIdSource: IdSource {
    private let seed: UInt32
    private var counter: UInt64 = 0

    init(traceId: String) {
        // FNV-1a over the traceId for a stable per-trace prefix.
        var h: UInt32 = 2_166_136_261
        for byte in traceId.utf8 {
            h ^= UInt32(byte)
            h = h &* 16_777_619
        }
        seed = h
    }

    mutating func nextId() -> UUID {
        counter += 1
        let s = String(format: "%08x-0000-4000-8000-%012llx", seed, counter)
        // Constructed from a valid template — force-unwrap is safe by format.
        return UUID(uuidString: s)!
    }
}

/// Clock port implementation driven entirely by trace event times.
/// (Qualified conformance: the stdlib also declares a `Clock` protocol.)
struct TraceClock: RaxhaCore.Clock {
    let current: Timestamp
    func now() -> Timestamp { current }
}
