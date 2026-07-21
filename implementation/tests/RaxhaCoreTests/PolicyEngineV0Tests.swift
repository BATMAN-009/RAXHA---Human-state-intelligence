import XCTest
@testable import RaxhaCore

// PolicyEngineV0 had ZERO direct unit tests before this file (AUDIT-002 mutation-testing
// finding M9: mutating .critical/.high to action .none — a real D17 veto-contract violation
// — shipped fully green because nothing exercised this function directly). These pin the
// current severity→action mapping exactly as shipped. This stub is DELIBERATELY incomplete
// pending RFC-001/002/003 (see the file header) — these tests assert what IS coded, not
// what the eventual Phase-4 engine should do; they must not be read as ratifying the mapping
// against RFC-002 (still undecided).

final class PolicyEngineV0Tests: XCTestCase {

    private func ts(_ mono: Int64) -> Timestamp { Timestamp(monotonicMs: mono, wallMs: mono) }

    private func risk(severity: RiskScore.Severity) -> RiskScore {
        RiskScore(id: UUID(), wearerId: UUID(), at: ts(0), value: 0.5, severity: severity,
                 humanStateRef: ts(0), candidates: [], rationale: [],
                 modelVersion: "v", thresholdVersion: "v", confidence: .coldStart(0.5))
    }

    func testHighAndCriticalBothMapToCountdownWithHighTrustCost() {
        for severity: RiskScore.Severity in [.high, .critical] {
            let decision = PolicyEngineV0.decide(id: UUID(), risk: risk(severity: severity), at: ts(0))
            XCTAssertEqual(decision.action, .countdown, "\(severity) must trigger a countdown")
            XCTAssertEqual(decision.countdownSeconds, PolicyEngineV0.defaultCountdownSeconds)
            XCTAssertEqual(decision.trustCost, .high)
            XCTAssertFalse(decision.rationale.isEmpty, "responder vocabulary (D15) — rationale must be human-readable")
        }
    }

    func testModerateMapsToCheckInWithNoCountdown() {
        let decision = PolicyEngineV0.decide(id: UUID(), risk: risk(severity: .moderate), at: ts(0))
        XCTAssertEqual(decision.action, .checkIn)
        XCTAssertNil(decision.countdownSeconds, "check-in is not a timed escalation")
        XCTAssertEqual(decision.trustCost, .low)
    }

    func testLowMapsToNoneWithNoTrustCost() {
        let decision = PolicyEngineV0.decide(id: UUID(), risk: risk(severity: .low), at: ts(0))
        XCTAssertEqual(decision.action, .none)
        XCTAssertNil(decision.countdownSeconds)
        XCTAssertEqual(decision.trustCost, .none)
    }

    func testDecisionCarriesRiskRefAndDecidedAt() {
        let r = risk(severity: .high)
        let decision = PolicyEngineV0.decide(id: UUID(), risk: r, at: ts(777))
        XCTAssertEqual(decision.riskRef, r.id)
        XCTAssertEqual(decision.decidedAt, ts(777))
    }

    func testPolicyVersionIsStampedAndNonEmpty() {
        let decision = PolicyEngineV0.decide(id: UUID(), risk: risk(severity: .low), at: ts(0))
        XCTAssertEqual(decision.policyVersion, PolicyEngineV0.policyVersion)
        XCTAssertFalse(decision.policyVersion.isEmpty)
    }

    // Deterministic replayability (ADR-008): identical inputs, run twice, must yield an
    // identical decision in every field the harness hashes.
    func testDecisionIsDeterministicForIdenticalInputs() {
        let r = risk(severity: .high)
        let id = UUID()
        let d1 = PolicyEngineV0.decide(id: id, risk: r, at: ts(42))
        let d2 = PolicyEngineV0.decide(id: id, risk: r, at: ts(42))
        XCTAssertEqual(d1.action, d2.action)
        XCTAssertEqual(d1.countdownSeconds, d2.countdownSeconds)
        XCTAssertEqual(d1.rationale, d2.rationale)
        XCTAssertEqual(d1.trustCost, d2.trustCost)
    }
}
