import XCTest
@testable import RaxhaCore

// Domain tests — 08B fidelity: every object round-trips through Codable, and the wire
// spellings match the frozen dictionary exactly (frozen vocabulary is a standing rule;
// synonyms are how architectures rot).

final class DomainTests: XCTestCase {

    private let ts = Timestamp(monotonicMs: 1000, wallMs: 1_784_073_601_000)
    private let wearer = UUID(uuidString: "0A000000-0000-4000-8000-000000000001")!

    func testFrozenEnumSpellings() throws {
        // The snake_case rulings from 08B — a rename here is an RFC, not a refactor.
        XCTAssertEqual(Confidence.Basis.coldStart.rawValue, "cold_start")
        XCTAssertEqual(SensorEvidence.Source.onboardSensor.rawValue, "onboard_sensor")
        XCTAssertEqual(SensorEvidence.Source.platformDetection.rawValue, "platform_detection")
        XCTAssertEqual(SensorEvidence.Kind.platformFall.rawValue, "platform_fall")
        XCTAssertEqual(SensorEvidence.Kind.heartRate.rawValue, "heart_rate")
        XCTAssertEqual(SensorEvidence.Kind.onBody.rawValue, "on_body")
        XCTAssertEqual(Baseline.Timescale.shortDays.rawValue, "short_days")
        XCTAssertEqual(Baseline.Maturity.coldStart.rawValue, "cold_start")
        XCTAssertEqual(PolicyDecision.Action.checkIn.rawValue, "check_in")
        XCTAssertEqual(Incident.Resolution.userCancel.rawValue, "user_cancel")
        XCTAssertEqual(Incident.Resolution.contactAck.rawValue, "contact_ack")
        XCTAssertEqual(Incident.Resolution.timeoutEscalated.rawValue, "timeout_escalated")
        XCTAssertEqual(Incident.Resolution.falseAlarmConfirmed.rawValue, "false_alarm_confirmed")
    }

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws {
        let data = try JSONEncoder().encode(value)
        let back = try JSONDecoder().decode(T.self, from: data)
        XCTAssertEqual(back, value)
    }

    func testCodableRoundTrips() throws {
        let confidence = Confidence.coldStart(0.9)
        let evidence = SensorEvidence(
            id: UUID(), wearerId: wearer, source: .platformDetection, kind: .platformFall,
            values: [1.0], unit: "detection", quality: 0.95, confidence: confidence,
            measuredAt: ts, receivedAt: ts.adding(milliseconds: 10))
        try roundTrip(evidence)

        let state = HumanState.allUnknown(wearerId: wearer, at: ts)
        try roundTrip(state)

        let risk = RiskScore(
            id: UUID(), wearerId: wearer, at: ts, value: 0.9, severity: .high,
            humanStateRef: ts, candidates: [evidence.id], rationale: ["platform fall detection"],
            modelVersion: "risk-v0.0.1-rules", thresholdVersion: "thresholds-v0.0.1-provisional",
            confidence: confidence)
        try roundTrip(risk)

        let decision = PolicyDecision(
            id: UUID(), riskRef: risk.id, action: .countdown, countdownSeconds: 30,
            rationale: "test", policyVersion: "policy-v0.0.1-phase0-stub", decidedAt: ts, trustCost: .high)
        try roundTrip(decision)

        let escalation = EscalationState(state: .COUNTDOWN, enteredAt: ts,
                                         deadlineAt: ts.adding(milliseconds: 30000),
                                         seq: 2, fsmVersion: fsmVersion)
        try roundTrip(escalation)

        let incident = Incident(
            id: UUID(), wearerId: wearer, openedAt: ts, cause: decision.id,
            escalation: escalation, stateSnapshot: state,
            location: .init(lat: 17.4, lon: 78.5, uncertaintyMeters: 25, ageSeconds: 4, source: "gps"),
            timeline: [.transition(escalation), .alert(alertId: UUID(), at: ts)],
            resolvedAt: nil, resolution: nil)
        try roundTrip(incident)

        let envelope = EventEnvelope(
            eventId: UUID(), incidentId: incident.id, seq: 1, type: "incident_opened",
            payload: .object(["severity": .string("high"), "countdownSeconds": .int(30)]),
            createdAt: ts, deviceId: "watch-01", fsmVersion: fsmVersion)
        try roundTrip(envelope)

        let alert = AlertEnvelope(
            alertId: UUID(), incidentId: incident.id, contactId: UUID(), rung: .push,
            summary: "Possible fall detected", locationShare: .init(token: "t", expiresAt: ts),
            sentAt: ts)
        try roundTrip(alert)

        let contact = Contact(
            id: UUID(), wearerId: wearer, name: "Test Contact", relationship: "child",
            channels: [.init(rung: .push, address: "device-token", criticalAlertCapable: true)],
            escalationOrder: 1, consent: .accepted)
        try roundTrip(contact)

        let coverage = DeviceCoverage(
            wearerId: wearer, at: ts, protection: .degraded, wornState: .worn,
            battery: .init(watch: 0.4), links: .init(watchPhone: .up, phoneCloud: .down),
            permissions: .init(location: .granted, notifications: .granted, health: .granted, motion: .granted),
            gaps: [.init(from: ts, to: ts.adding(milliseconds: 60000), cause: "phone_cloud_link_down")])
        try roundTrip(coverage)
    }

    func testLocationNeverWithoutUncertaintyAndAge() throws {
        // D15 structurally: Incident.Location cannot be constructed or decoded without
        // uncertaintyMeters + ageSeconds.
        let json = #"{"lat": 17.4, "lon": 78.5}"#.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.Location.self, from: json))
    }

    func testTimestampOrderingIsMonotonicOnly() {
        let a = Timestamp(monotonicMs: 100, wallMs: 9_999_999_999_999)
        let b = Timestamp(monotonicMs: 200, wallMs: 0) // wall clock jumped backward
        XCTAssertTrue(a < b, "ordering must follow the monotonic leg, not the wall leg")
    }
}
