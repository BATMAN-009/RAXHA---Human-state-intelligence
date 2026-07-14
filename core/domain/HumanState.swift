import Foundation

// 08B Part B: `HumanState` — the single canonical estimate (ADR-006).
// `unknown` is a first-class value in every enum (D13): absence of evidence is
// representable, never defaulted to "normal".

public struct HumanState: Codable, Hashable, Sendable {
    public enum Posture: String, Codable, Sendable {
        case upright, sitting, lying, unknown
    }

    public enum Motion: String, Codable, Sendable {
        case still, walking, active, vehicle, unknown
    }

    public enum PlaceContext: String, Codable, Sendable {
        case home, known, unknown, unavailable
    }

    public struct Physiology: Codable, Hashable, Sendable {
        public var hr: Double?
        public var hrDeviationFromBaseline: Double?
        public init(hr: Double? = nil, hrDeviationFromBaseline: Double? = nil) {
            self.hr = hr
            self.hrDeviationFromBaseline = hrDeviationFromBaseline
        }
    }

    public var wearerId: UUID
    public var at: Timestamp
    public var posture: Posture
    public var motion: Motion
    public var physiology: Physiology
    public var placeContext: PlaceContext
    public var confidence: Confidence
    public var contributingEvidence: [UUID]
    public var baselineMaturity: Baseline.Maturity

    public init(wearerId: UUID, at: Timestamp, posture: Posture, motion: Motion,
                physiology: Physiology, placeContext: PlaceContext, confidence: Confidence,
                contributingEvidence: [UUID], baselineMaturity: Baseline.Maturity) {
        self.wearerId = wearerId
        self.at = at
        self.posture = posture
        self.motion = motion
        self.physiology = physiology
        self.placeContext = placeContext
        self.confidence = confidence
        self.contributingEvidence = contributingEvidence
        self.baselineMaturity = baselineMaturity
    }

    /// The honest starting state: everything unknown, visibly cold-start (D13/D18).
    public static func allUnknown(wearerId: UUID, at: Timestamp) -> HumanState {
        HumanState(wearerId: wearerId, at: at, posture: .unknown, motion: .unknown,
                   physiology: Physiology(), placeContext: .unavailable,
                   confidence: .coldStart(0.0), contributingEvidence: [], baselineMaturity: .coldStart)
    }
}
