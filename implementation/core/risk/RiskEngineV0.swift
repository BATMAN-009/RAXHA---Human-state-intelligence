import Foundation

// Risk Engine v0 — rule-based, interpretable, replay-testable (TD-1: this heuristic must
// be replaced before any ML-grade recall claim). Phase-0 skeleton of the Phase-3 subsystem.
// Deterministic per evaluation (IF-INT-03): same inputs ⇒ same output. Both version stamps
// are mandatory (SRS-302) — every score is traceable to the artifacts that produced it.

public enum RiskEngineV0 {
    public static let modelVersion = "risk-v0.0.1-rules"
    public static let thresholdVersion = "thresholds-v0.0.1-provisional"

    /// v0 rule: a platform fall detection with the wearer down and still elevates risk in
    /// proportion to evidence confidence. Everything else scores low. Honest cold-start
    /// confidence provenance — nothing here is calibrated yet (D18).
    public static func evaluate(id: UUID, state: HumanState, candidates: [SensorEvidence],
                                at: Timestamp) -> RiskScore
    {
        var value = 0.05
        var severity: RiskScore.Severity = .low
        var rationale: [String] = []

        let fall = candidates.first { $0.kind == .platformFall }
        if let fall {
            value = max(value, fall.confidence.value)
            rationale.append("platform fall detection (quality \(fall.quality))")
            if state.posture == .lying && state.motion == .still {
                value = min(1.0, value + 0.15)
                rationale.append("wearer lying and still after impact")
            }
            severity = value >= 0.75 ? .high : .moderate
        } else {
            rationale.append("no candidate event")
        }

        return RiskScore(
            id: id, wearerId: state.wearerId, at: at, value: value, severity: severity,
            humanStateRef: state.at, candidates: candidates.map(\.id), rationale: rationale,
            modelVersion: modelVersion, thresholdVersion: thresholdVersion,
            confidence: .coldStart(value))
    }
}
