// 08B Part B logical type Timestamp{monotonic, wall}.
// Integer milliseconds on both legs — floats never enter hashed decision logs (ADR-109).
// The core NEVER reads a clock; every Timestamp arrives through the Clock port or trace data.

public struct Timestamp: Codable, Hashable, Comparable, Sendable {
    /// Milliseconds on the device's monotonic clock (ordering, deadlines).
    public var monotonicMs: Int64
    /// Milliseconds since Unix epoch, wall clock (human/report time; never used for ordering).
    public var wallMs: Int64

    public init(monotonicMs: Int64, wallMs: Int64) {
        self.monotonicMs = monotonicMs
        self.wallMs = wallMs
    }

    /// Ordering is monotonic-clock only (D11: wall clocks jump; deadlines must not).
    public static func < (lhs: Timestamp, rhs: Timestamp) -> Bool {
        lhs.monotonicMs < rhs.monotonicMs
    }

    public func adding(milliseconds: Int64) -> Timestamp {
        Timestamp(monotonicMs: monotonicMs + milliseconds, wallMs: wallMs + milliseconds)
    }
}
