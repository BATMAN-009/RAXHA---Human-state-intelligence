import XCTest
import RaxhaCore
@testable import RaxhaHarnessKit

// The verifier, independently challenged. Every test here feeds the rig input it is SUPPOSED
// to reject and asserts it does. If any of AUDIT-002's mutation-survivors is reintroduced —
// vacuous gate, `return []` in the validator, `pass = true` in the determinism rig, dropping
// the baseline compare — one of these tests goes red. That is the property the Phase-0 gate
// previously lacked: it had never been asked to fail.

final class HarnessTests: XCTestCase {

    // MARK: fixtures

    private func trace(_ json: String) throws -> Trace {
        try JSONDecoder().decode(Trace.self, from: Data(json.utf8))
    }

    private let wearer = "0A000000-0000-4000-8000-000000000001"

    /// One tick, no evidence: exercises no interface. A corpus that certifies this proves nothing.
    private var vacuousTrace: String {
        """
        {"schemaVersion":"trace-v0.1","traceId":"t-vacuous","description":"","wearerId":"\(wearer)",
         "events":[{"at":{"monotonicMs":1000,"wallMs":1784073601000},"action":"tick"}]}
        """
    }

    /// A platform fall that goes unanswered: exercises IF-INT-01…05 including a real Incident.
    private var fallTrace: String {
        """
        {"schemaVersion":"trace-v0.1","traceId":"t-fall","description":"","wearerId":"\(wearer)","events":[
          {"at":{"monotonicMs":5000,"wallMs":1784073605000},"evidence":{"id":"E0000000-0000-4000-8000-000000000101",
            "wearerId":"\(wearer)","source":"platform_detection","kind":"platform_fall","values":[1.0],"unit":"detection",
            "quality":0.95,"confidence":{"value":0.9,"calibrationMethod":"none","calibrationVersion":"uncalibrated","basis":"cold_start"},
            "measuredAt":{"monotonicMs":5000,"wallMs":1784073605000},"receivedAt":{"monotonicMs":5010,"wallMs":1784073605010}}},
          {"at":{"monotonicMs":40000,"wallMs":1784073640000},"action":"tick"},
          {"at":{"monotonicMs":170000,"wallMs":1784073770000},"action":"tick"},
          {"at":{"monotonicMs":175000,"wallMs":1784073775000},"action":"resolveContactAck"}
        ]}
        """
    }

    /// Evidence whose receivedAt precedes measuredAt — a contract violation IF-INT-01 must flag.
    private var timeTravelTrace: String {
        """
        {"schemaVersion":"trace-v0.1","traceId":"t-timetravel","description":"","wearerId":"\(wearer)","events":[
          {"at":{"monotonicMs":5000,"wallMs":1784073605000},"evidence":{"id":"E0000000-0000-4000-8000-000000000201",
            "wearerId":"\(wearer)","source":"onboard_sensor","kind":"motion","values":[0.3],"unit":"activity_index",
            "quality":0.9,"confidence":{"value":0.8,"calibrationMethod":"none","calibrationVersion":"uncalibrated","basis":"cold_start"},
            "measuredAt":{"monotonicMs":5000,"wallMs":1784073605000},"receivedAt":{"monotonicMs":4000,"wallMs":1784073604000}}}
        ]}
        """
    }

    private func schemas() throws -> ContractSchemas {
        // Locate the committed schema relative to this source file (no CWD assumption).
        let here = URL(fileURLWithPath: #filePath)
        let root = here.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try ContractSchemas(schemaFileURL: root.appendingPathComponent("shared/contracts/if-int-objects.schema.json"))
    }

    // MARK: VV-110 — the contract gate must REJECT, not rubber-stamp

    func testVacuousCorpusIsBlockedNotPassed() throws {
        let report = try Rigs.contracts(traces: [try trace(vacuousTrace)], schemas: try schemas())
        XCTAssertEqual(report.status, "BLOCKED",
                       "a corpus that exercises no interface must BLOCK, never PASS (the vacuous-gate fix)")
        // And no required interface may be reported CONFORMS on zero objects.
        for i in report.interfaces where i.id.hasPrefix("IF-INT-0") && Int(i.id.suffix(1)) ?? 9 <= 5 {
            if i.objectsChecked == 0 { XCTAssertNotEqual(i.status, "CONFORMS", "\(i.id) CONFORMS on 0 objects") }
        }
    }

    func testRealFallCorpusPassesAndValidatesTheIncident() throws {
        let report = try Rigs.contracts(traces: [try trace(fallTrace)], schemas: try schemas())
        XCTAssertEqual(report.status, "PASS")
        let ifint05 = report.interfaces.first { $0.id == "IF-INT-05" }
        XCTAssertNotNil(ifint05)
        // IF-INT-05's contract object is Incident + EscalationState — a real Incident must be validated.
        XCTAssertGreaterThan(ifint05?.objectsChecked ?? 0, 0, "IF-INT-05 must validate real journal + Incident objects")
        XCTAssertEqual(ifint05?.status, "CONFORMS")
    }

    func testContractGateCatchesReceivedBeforeMeasured() throws {
        let report = try Rigs.contracts(traces: [try trace(timeTravelTrace)], schemas: try schemas())
        XCTAssertEqual(report.status, "FAIL", "receivedAt < measuredAt must fail the contract gate")
        let ifint01 = report.interfaces.first { $0.id == "IF-INT-01" }
        XCTAssertEqual(ifint01?.status, "VIOLATIONS")
    }

    // MARK: the schema validator must catch corrupted objects

    func testValidatorRejectsOutOfRangeConfidence() throws {
        let bad = SensorEvidence(
            id: UUID(), wearerId: UUID(), source: .onboardSensor, kind: .motion, values: [0.1], unit: "x",
            quality: 0.9, confidence: Confidence(value: 1.5, calibrationMethod: .none, calibrationVersion: "u", basis: .coldStart),
            measuredAt: Timestamp(monotonicMs: 1, wallMs: 1), receivedAt: Timestamp(monotonicMs: 2, wallMs: 2))
        let violations = try schemas().validate(bad, against: "SensorEvidence")
        XCTAssertFalse(violations.isEmpty, "confidence.value = 1.5 (> 1) must be rejected")
    }

    func testValidatorRejectsEmptyVersionStamp() throws {
        let bad = RiskScore(
            id: UUID(), wearerId: UUID(), at: Timestamp(monotonicMs: 1, wallMs: 1), value: 0.5, severity: .low,
            humanStateRef: Timestamp(monotonicMs: 1, wallMs: 1), candidates: [], rationale: [],
            modelVersion: "", thresholdVersion: "", // governed safety artifacts — must be non-empty (SRS-302)
            confidence: Confidence(value: 0.5, calibrationMethod: .none, calibrationVersion: "u", basis: .coldStart))
        let violations = try schemas().validate(bad, against: "RiskScore")
        XCTAssertFalse(violations.isEmpty, "empty modelVersion/thresholdVersion must be rejected (minLength)")
    }

    func testValidatorAcceptsAWellFormedObject() throws {
        let ok = SensorEvidence(
            id: UUID(), wearerId: UUID(), source: .onboardSensor, kind: .motion, values: [0.1], unit: "x",
            quality: 0.9, confidence: Confidence(value: 0.8, calibrationMethod: .none, calibrationVersion: "u", basis: .coldStart),
            measuredAt: Timestamp(monotonicMs: 1, wallMs: 1), receivedAt: Timestamp(monotonicMs: 2, wallMs: 2))
        XCTAssertTrue(try schemas().validate(ok, against: "SensorEvidence").isEmpty,
                      "a valid object must pass — otherwise the gate is uselessly strict")
    }

    // MARK: VV-101 — determinism must be pinned to a committed baseline

    func testDeterminismFailsOnBaselineDrift() throws {
        let report = try Rigs.determinism(
            traces: [try trace(fallTrace)], runs: 2, toolchain: "test",
            baseline: ["t-fall": "0000000000000000000000000000000000000000000000000000000000000000"])
        XCTAssertEqual(report.status, "FAIL", "a decision-log hash that differs from the golden baseline must FAIL")
        XCTAssertEqual(report.traces.first?.baselineStatus, "CHANGED")
    }

    func testDeterminismBlocksWhenNoBaselineExists() throws {
        let report = try Rigs.determinism(traces: [try trace(fallTrace)], runs: 2, toolchain: "test")
        XCTAssertEqual(report.status, "BLOCKED", "an exercised trace with no committed baseline cannot be certified — BLOCKED, not PASS")
    }

    func testDeterminismPassesOnlyWithMatchingBaseline() throws {
        // Establish the golden hash, then require it.
        let established = try Rigs.determinism(traces: [try trace(fallTrace)], runs: 2, toolchain: "test", rebaseline: true)
        let golden = try XCTUnwrap(established.traces.first?.hashes.first)
        let verified = try Rigs.determinism(traces: [try trace(fallTrace)], runs: 2, toolchain: "test", baseline: ["t-fall": golden])
        XCTAssertEqual(verified.status, "PASS")
        XCTAssertEqual(verified.traces.first?.baselineStatus, "MATCH")
    }

    func testVacuousTraceIsNotADeterminismPass() throws {
        // Determinism of "nothing" is meaningless — an empty-log corpus must not read PASS.
        let report = try Rigs.determinism(traces: [try trace(vacuousTrace)], runs: 2, toolchain: "test", rebaseline: true)
        XCTAssertNotEqual(report.status, "PASS", "an empty decision log must not certify as a determinism PASS")
    }
}
