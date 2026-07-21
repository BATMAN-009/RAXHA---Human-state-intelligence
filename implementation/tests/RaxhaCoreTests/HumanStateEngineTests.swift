import XCTest
@testable import RaxhaCore

// HumanStateEngine had ZERO direct unit tests before this file (AUDIT-002 mutation-testing
// finding: M10 — treating a gap marker as a no-op ships fully green because nothing exercises
// the engine directly, only indirectly through replay). These tests pin the CURRENT v0 stub
// behavior exactly as shipped — including the known, already-disposed BY_DESIGN gaps (stale-state
// restamping) — so a future change to this Phase-2-bound skeleton is a deliberate, visible diff.

final class HumanStateEngineTests: XCTestCase {

    private let wearer = UUID(uuidString: "0A000000-0000-4000-8000-000000000001")!
    private func ts(_ mono: Int64) -> Timestamp { Timestamp(monotonicMs: mono, wallMs: 1_784_073_600_000 + mono) }

    private func evidence(kind: SensorEvidence.Kind, values: [Double] = [],
                         confidence: Confidence = .coldStart(0.8), at: Timestamp) -> SensorEvidence {
        SensorEvidence(id: UUID(), wearerId: wearer, source: .onboardSensor, kind: kind,
                      values: values, unit: "x", quality: 0.9, confidence: confidence,
                      measuredAt: at, receivedAt: at)
    }

    func testInitialStateIsAllUnknown() {
        let hse = HumanStateEngine(wearerId: wearer, at: ts(0))
        XCTAssertEqual(hse.current.posture, .unknown)
        XCTAssertEqual(hse.current.motion, .unknown)
        XCTAssertEqual(hse.current.placeContext, .unavailable)
        XCTAssertEqual(hse.current.baselineMaturity, .coldStart)
        XCTAssertEqual(hse.current.confidence.basis, .coldStart)
        XCTAssertTrue(hse.current.contributingEvidence.isEmpty)
    }

    func testGapMarkerWidensToUnknownEvenFromAnEstablishedState() {
        var hse = HumanStateEngine(wearerId: wearer, at: ts(0))
        _ = hse.ingest(evidence(kind: .platformFall, values: [1.0], confidence: .coldStart(0.9), at: ts(1000)))
        XCTAssertEqual(hse.current.posture, .lying, "precondition: state must be established before the gap")

        let afterGap = hse.ingest(evidence(kind: .gap, at: ts(2000)))
        XCTAssertEqual(afterGap.posture, .unknown, "D13: loss must widen, never silently hold the prior value")
        XCTAssertEqual(afterGap.motion, .unknown)
        XCTAssertNil(afterGap.physiology.hr)
        XCTAssertEqual(afterGap.confidence.value, 0.0)
        XCTAssertEqual(afterGap.confidence.basis, .coldStart)
    }

    func testPlatformFallSetsLyingAndStillWithEvidenceConfidence() {
        var hse = HumanStateEngine(wearerId: wearer, at: ts(0))
        let conf = Confidence(value: 0.92, calibrationMethod: .none, calibrationVersion: "uncalibrated", basis: .coldStart)
        let state = hse.ingest(evidence(kind: .platformFall, values: [1.0], confidence: conf, at: ts(500)))
        XCTAssertEqual(state.posture, .lying)
        XCTAssertEqual(state.motion, .still)
        XCTAssertEqual(state.confidence.value, 0.92)
    }

    func testMotionAboveThresholdIsActiveBelowIsStill() {
        var hse = HumanStateEngine(wearerId: wearer, at: ts(0))
        let active = hse.ingest(evidence(kind: .motion, values: [0.9], at: ts(100)))
        XCTAssertEqual(active.motion, .active)
        let still = hse.ingest(evidence(kind: .motion, values: [0.1], at: ts(200)))
        XCTAssertEqual(still.motion, .still)
    }

    func testMotionWithNoValueIsUnknownNotDefaultedToStill() {
        var hse = HumanStateEngine(wearerId: wearer, at: ts(0))
        let state = hse.ingest(evidence(kind: .motion, values: [], at: ts(100)))
        XCTAssertEqual(state.motion, .unknown, "D13: absence of a value must not silently default to a normal-looking state")
    }

    func testHeartRateSetsPhysiologyHR() {
        var hse = HumanStateEngine(wearerId: wearer, at: ts(0))
        let state = hse.ingest(evidence(kind: .heartRate, values: [71.0], at: ts(300)))
        XCTAssertEqual(state.physiology.hr, 71.0)
    }

    func testUnrelatedKindDoesNotMoveStateButIsRecordedAsContributing() {
        var hse = HumanStateEngine(wearerId: wearer, at: ts(0))
        _ = hse.ingest(evidence(kind: .motion, values: [0.9], at: ts(100))) // establish .active
        let e = evidence(kind: .rotation, values: [12.0], at: ts(150))
        let state = hse.ingest(e)
        XCTAssertEqual(state.motion, .active, "an unhandled kind must not silently reset an established channel")
        XCTAssertTrue(state.contributingEvidence.contains(e.id))
    }

    func testContributingEvidenceAccumulatesAcrossIngests() {
        var hse = HumanStateEngine(wearerId: wearer, at: ts(0))
        let e1 = evidence(kind: .motion, values: [0.9], at: ts(100))
        let e2 = evidence(kind: .heartRate, values: [70], at: ts(200))
        _ = hse.ingest(e1)
        let state = hse.ingest(e2)
        XCTAssertEqual(state.contributingEvidence, [e1.id, e2.id])
    }

    // Pins a KNOWN, already-disposed (BY_DESIGN, AUDIT-002) gap: `at` and the whole-state
    // `confidence` are restamped by ANY incoming evidence, including one that doesn't touch
    // posture/motion — so an hour-old posture can be re-presented under a fresh timestamp and a
    // new, unrelated confidence value. This is Phase-2-bound stub behavior, not a Phase-0 defect;
    // the test exists so a change to it is a deliberate, visible diff, not a silent one.
    func testKnownGap_UnrelatedEvidenceRestampsTimeAndConfidence() {
        var hse = HumanStateEngine(wearerId: wearer, at: ts(0))
        _ = hse.ingest(evidence(kind: .platformFall, values: [1.0], confidence: .coldStart(0.9), at: ts(1000)))
        let laterHR = evidence(kind: .heartRate, values: [70], confidence: .coldStart(0.3), at: ts(3_600_000))
        let state = hse.ingest(laterHR)
        XCTAssertEqual(state.posture, .lying, "posture carries forward untouched")
        XCTAssertEqual(state.at.monotonicMs, 3_600_000, "KNOWN GAP: `at` moves even though posture didn't change")
        XCTAssertEqual(state.confidence.value, 0.3, "KNOWN GAP: whole-state confidence is overwritten by an unrelated channel's confidence")
    }
}
