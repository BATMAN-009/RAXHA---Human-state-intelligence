import XCTest
@testable import RaxhaCore

// RiskEngineV0 had ZERO direct unit tests before this file (AUDIT-002 mutation-testing
// findings M7/M9: a risk engine that never raises severity, or a policy that vetoes high
// severity, shipped fully green because nothing exercised these functions directly). These
// pin the v0 rule-based heuristic exactly as shipped (TD-1: to be replaced pre any ML-grade
// recall claim) so a silent regression in the escalation-triggering logic is caught here,
// not only in end-to-end replay.

final class RiskEngineV0Tests: XCTestCase {

    private let wearer = UUID(uuidString: "0A000000-0000-4000-8000-000000000001")!
    private func ts(_ mono: Int64) -> Timestamp { Timestamp(monotonicMs: mono, wallMs: mono) }

    private func humanState(posture: HumanState.Posture = .unknown, motion: HumanState.Motion = .unknown) -> HumanState {
        var s = HumanState.allUnknown(wearerId: wearer, at: ts(0))
        s.posture = posture
        s.motion = motion
        return s
    }

    private func fallEvidence(confidence: Double, quality: Double = 0.9) -> SensorEvidence {
        SensorEvidence(id: UUID(), wearerId: wearer, source: .platformDetection, kind: .platformFall,
                      values: [1.0], unit: "detection", quality: quality,
                      confidence: Confidence(value: confidence, calibrationMethod: .none, calibrationVersion: "u", basis: .coldStart),
                      measuredAt: ts(0), receivedAt: ts(0))
    }

    func testNoCandidateScoresLowWithHonestRationale() {
        let risk = RiskEngineV0.evaluate(id: UUID(), state: humanState(), candidates: [], at: ts(0))
        XCTAssertEqual(risk.severity, .low)
        XCTAssertEqual(risk.value, 0.05)
        XCTAssertEqual(risk.rationale, ["no candidate event"])
    }

    func testPlatformFallAloneWithoutLyingStillCapsAtModerateBelow075() {
        // confidence 0.6, no posture corroboration → value stays 0.6, below the 0.75 severity cutoff.
        let risk = RiskEngineV0.evaluate(id: UUID(), state: humanState(), candidates: [fallEvidence(confidence: 0.6)], at: ts(0))
        XCTAssertEqual(risk.value, 0.6, accuracy: 1e-9)
        XCTAssertEqual(risk.severity, .moderate)
    }

    func testPlatformFallWithLyingAndStillCorroborationReachesHigh() {
        let state = humanState(posture: .lying, motion: .still)
        let risk = RiskEngineV0.evaluate(id: UUID(), state: state, candidates: [fallEvidence(confidence: 0.7)], at: ts(0))
        XCTAssertEqual(risk.value, 0.85, accuracy: 1e-9, "0.7 + 0.15 corroboration bonus")
        XCTAssertEqual(risk.severity, .high, "0.85 >= 0.75 severity threshold")
        XCTAssertTrue(risk.rationale.contains("wearer lying and still after impact"))
    }

    func testValueIsCappedAtOnePointZero() {
        let state = humanState(posture: .lying, motion: .still)
        let risk = RiskEngineV0.evaluate(id: UUID(), state: state, candidates: [fallEvidence(confidence: 0.95)], at: ts(0))
        XCTAssertLessThanOrEqual(risk.value, 1.0)
        XCTAssertEqual(risk.value, 1.0, accuracy: 1e-9, "min(1.0, 0.95 + 0.15) saturates at 1.0")
    }

    func testSeverityThresholdBoundaryAt075() {
        let state = humanState(posture: .lying, motion: .still)
        // 0.60 + 0.15 = 0.75 exactly → high (>=).
        let atBoundary = RiskEngineV0.evaluate(id: UUID(), state: state, candidates: [fallEvidence(confidence: 0.60)], at: ts(0))
        XCTAssertEqual(atBoundary.value, 0.75, accuracy: 1e-9)
        XCTAssertEqual(atBoundary.severity, .high, "boundary is inclusive (>=), not exclusive")

        // 0.59 + 0.15 = 0.74 → moderate.
        let belowBoundary = RiskEngineV0.evaluate(id: UUID(), state: state, candidates: [fallEvidence(confidence: 0.59)], at: ts(0))
        XCTAssertEqual(belowBoundary.severity, .moderate)
    }

    func testGovernedVersionStampsAreAlwaysPresentAndNonEmpty() {
        let risk = RiskEngineV0.evaluate(id: UUID(), state: humanState(), candidates: [], at: ts(0))
        XCTAssertEqual(risk.modelVersion, RiskEngineV0.modelVersion)
        XCTAssertEqual(risk.thresholdVersion, RiskEngineV0.thresholdVersion)
        XCTAssertFalse(risk.modelVersion.isEmpty)
        XCTAssertFalse(risk.thresholdVersion.isEmpty)
    }

    func testConfidenceIsHonestlyColdStartNotMasqueradingAsCalibrated() {
        let risk = RiskEngineV0.evaluate(id: UUID(), state: humanState(), candidates: [fallEvidence(confidence: 0.8)], at: ts(0))
        XCTAssertEqual(risk.confidence.basis, .coldStart, "D18: nothing in v0 is calibrated yet — must not masquerade as calibrated")
        XCTAssertEqual(risk.confidence.value, risk.value, "cold-start confidence mirrors the raw value")
    }

    func testCandidatesAndHumanStateRefAreCarriedThrough() {
        let fall = fallEvidence(confidence: 0.8)
        let state = humanState(posture: .lying, motion: .still)
        let risk = RiskEngineV0.evaluate(id: UUID(), state: state, candidates: [fall], at: ts(500))
        XCTAssertEqual(risk.candidates, [fall.id])
        XCTAssertEqual(risk.humanStateRef, state.at)
        XCTAssertEqual(risk.wearerId, state.wearerId)
    }
}
