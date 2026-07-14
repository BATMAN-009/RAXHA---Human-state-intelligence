import Foundation

// 08B Part B: `SensorEvidence`. Staleness = now − measuredAt, always computable
// (measured-time, not received-time). A platform detection is just another `source` —
// evidence, never authority (ADR-004).

public struct SensorEvidence: Codable, Hashable, Sendable {
    public enum Source: String, Codable, Sendable {
        case onboardSensor = "onboard_sensor"
        case platformDetection = "platform_detection"
        case derived
    }

    // 08B lists this set with "…" (open list). Adding a kind is an 08B Part B revision,
    // not an ad-hoc code edit — extend here only in lockstep with the dictionary.
    public enum Kind: String, Codable, Sendable {
        case motion
        case rotation
        case orientation
        case heartRate = "heart_rate"
        case hrv
        case location
        case pressure
        case onBody = "on_body"
        case platformFall = "platform_fall"
        /// Explicit gap marker: loss is tolerated but never silent (IF-INT-01, D13).
        case gap
    }

    public var id: UUID
    public var wearerId: UUID
    public var source: Source
    public var kind: Kind
    public var values: [Double]
    public var unit: String
    /// Signal quality index, 0...1.
    public var quality: Double
    public var confidence: Confidence
    public var measuredAt: Timestamp
    public var receivedAt: Timestamp

    public init(id: UUID, wearerId: UUID, source: Source, kind: Kind, values: [Double], unit: String,
                quality: Double, confidence: Confidence, measuredAt: Timestamp, receivedAt: Timestamp) {
        self.id = id
        self.wearerId = wearerId
        self.source = source
        self.kind = kind
        self.values = values
        self.unit = unit
        self.quality = quality
        self.confidence = confidence
        self.measuredAt = measuredAt
        self.receivedAt = receivedAt
    }
}

// 08B Part B: `Baseline` — one record per (signal × timescale); the multi-timescale design
// that keeps slow pathology from hiding in adaptation (D16). Never leaves the device
// unaggregated (D05/D21).
public struct Baseline: Codable, Hashable, Sendable {
    public enum Timescale: String, Codable, Sendable {
        case shortDays = "short_days"
        case mediumWeeks = "medium_weeks"
        case longMonths = "long_months"
    }

    public enum Maturity: String, Codable, Sendable {
        case coldStart = "cold_start"
        case calibrating
        case established
    }

    public struct Distribution: Codable, Hashable, Sendable {
        public var center: Double
        public var spread: Double
        public init(center: Double, spread: Double) {
            self.center = center
            self.spread = spread
        }
    }

    public var wearerId: UUID
    public var signalKind: SensorEvidence.Kind
    public var timescale: Timescale
    public var distribution: Distribution
    public var sampleCount: Int
    public var updatedAt: Timestamp
    public var maturity: Maturity

    public init(wearerId: UUID, signalKind: SensorEvidence.Kind, timescale: Timescale,
                distribution: Distribution, sampleCount: Int, updatedAt: Timestamp, maturity: Maturity) {
        self.wearerId = wearerId
        self.signalKind = signalKind
        self.timescale = timescale
        self.distribution = distribution
        self.sampleCount = sampleCount
        self.updatedAt = updatedAt
        self.maturity = maturity
    }
}
