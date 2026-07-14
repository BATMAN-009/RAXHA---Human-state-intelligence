// 08B Part B: `Confidence` — a calibrated probability WITH provenance.
// `none`/`cold_start` are representable and visible downstream: uncalibrated confidence
// must never masquerade as calibrated (D18).

public struct Confidence: Codable, Hashable, Sendable {
    public enum CalibrationMethod: String, Codable, Sendable {
        case temperature
        case isotonic
        case none
    }

    public enum Basis: String, Codable, Sendable {
        case measured
        case inferred
        case coldStart = "cold_start"
    }

    /// 0...1
    public var value: Double
    public var calibrationMethod: CalibrationMethod
    public var calibrationVersion: String
    public var basis: Basis

    public init(value: Double, calibrationMethod: CalibrationMethod, calibrationVersion: String, basis: Basis) {
        self.value = value
        self.calibrationMethod = calibrationMethod
        self.calibrationVersion = calibrationVersion
        self.basis = basis
    }

    /// Honest cold-start default: visibly uncalibrated (never a silent 1.0 or 0.5-as-if-measured).
    public static func coldStart(_ value: Double) -> Confidence {
        Confidence(value: value, calibrationMethod: .none, calibrationVersion: "uncalibrated", basis: .coldStart)
    }
}
