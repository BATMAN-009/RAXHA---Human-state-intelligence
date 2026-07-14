import XCTest
@testable import RaxhaCore

// FSM tests — every legal Blueprint A6 edge, illegal-edge rejection, persisted-deadline
// semantics, and the reboot-recovery contract (SRS-501/504: expired-while-dead FAILS
// TOWARD ALERTING). These are the L0 seeds of VV-106.

final class EscalationFSMTests: XCTestCase {

    private func ts(_ mono: Int64, wall: Int64? = nil) -> Timestamp {
        Timestamp(monotonicMs: mono, wallMs: wall ?? (1_784_073_600_000 + mono))
    }

    func testFullUnattendedLadder() throws {
        var s = EscalationFSM.initialState(at: ts(0))
        XCTAssertEqual(s.state, .IDLE)
        XCTAssertEqual(s.seq, 0)

        s = try EscalationFSM.transition(s, input: .suspect, now: ts(1000)).newState
        XCTAssertEqual(s.state, .SUSPECTED)

        s = try EscalationFSM.transition(s, input: .startCountdown(seconds: 30), now: ts(2000)).newState
        XCTAssertEqual(s.state, .COUNTDOWN)
        XCTAssertEqual(s.deadlineAt?.monotonicMs, 32000)

        s = try EscalationFSM.transition(s, input: .deadlineExpired, now: ts(32000)).newState
        XCTAssertEqual(s.state, .ALERTING)
        XCTAssertEqual(s.deadlineAt?.monotonicMs, 32000 + EscalationFSM.defaultAckDeadlineMs)

        s = try EscalationFSM.transition(s, input: .deadlineExpired,
                                         now: ts(32000 + EscalationFSM.defaultAckDeadlineMs)).newState
        XCTAssertEqual(s.state, .ESCALATING)

        s = try EscalationFSM.transition(s, input: .resolve(.timeoutEscalated), now: ts(200_000)).newState
        XCTAssertEqual(s.state, .RESOLVED)
        XCTAssertEqual(s.seq, 5)
    }

    func testAcknowledgedPath() throws {
        var s = EscalationFSM.initialState(at: ts(0))
        s = try EscalationFSM.transition(s, input: .suspect, now: ts(1000)).newState
        s = try EscalationFSM.transition(s, input: .startCountdown(seconds: 30), now: ts(2000)).newState
        s = try EscalationFSM.transition(s, input: .deadlineExpired, now: ts(40000)).newState
        s = try EscalationFSM.transition(s, input: .contactAcknowledged, now: ts(50000)).newState
        XCTAssertEqual(s.state, .ACKNOWLEDGED)
        s = try EscalationFSM.transition(s, input: .resolve(.contactAck), now: ts(60000)).newState
        XCTAssertEqual(s.state, .RESOLVED)
    }

    func testRejectAndCancelReturnToIdle() throws {
        var s = EscalationFSM.initialState(at: ts(0))
        s = try EscalationFSM.transition(s, input: .suspect, now: ts(1000)).newState
        s = try EscalationFSM.transition(s, input: .reject, now: ts(2000)).newState
        XCTAssertEqual(s.state, .IDLE)

        s = try EscalationFSM.transition(s, input: .suspect, now: ts(3000)).newState
        s = try EscalationFSM.transition(s, input: .startCountdown(seconds: 30), now: ts(4000)).newState
        s = try EscalationFSM.transition(s, input: .wearerCancel, now: ts(10000)).newState
        XCTAssertEqual(s.state, .IDLE)
    }

    func testIllegalEdgesThrow() {
        let idle = EscalationFSM.initialState(at: ts(0))
        XCTAssertThrowsError(try EscalationFSM.transition(idle, input: .wearerCancel, now: ts(1)))
        XCTAssertThrowsError(try EscalationFSM.transition(idle, input: .contactAcknowledged, now: ts(1)))
        XCTAssertThrowsError(try EscalationFSM.transition(idle, input: .resolve(.services), now: ts(1)))
    }

    func testDeadlineNotReachedThrows() throws {
        var s = EscalationFSM.initialState(at: ts(0))
        s = try EscalationFSM.transition(s, input: .suspect, now: ts(1000)).newState
        s = try EscalationFSM.transition(s, input: .startCountdown(seconds: 30), now: ts(2000)).newState
        XCTAssertThrowsError(try EscalationFSM.transition(s, input: .deadlineExpired, now: ts(10000))) {
            XCTAssertEqual($0 as? TransitionError, .deadlineNotReached)
        }
    }

    func testZeroSecondCountdownIsImmediatelyExpirable() throws {
        var s = EscalationFSM.initialState(at: ts(0))
        s = try EscalationFSM.transition(s, input: .suspect, now: ts(1000)).newState
        s = try EscalationFSM.transition(s, input: .startCountdown(seconds: 0), now: ts(2000)).newState
        s = try EscalationFSM.transition(s, input: .deadlineExpired, now: ts(2000)).newState
        XCTAssertEqual(s.state, .ALERTING)
    }

    func testRecoveryResumesUnexpiredCountdown() throws {
        let persisted = EscalationState(
            state: .COUNTDOWN, enteredAt: ts(2000), deadlineAt: ts(32000),
            seq: 2, fsmVersion: fsmVersion)
        let outcome = try EscalationFSM.recover(persisted: persisted, now: ts(10000))
        XCTAssertNil(outcome, "unexpired countdown must resume with its persisted deadline")
    }

    func testRecoveryFailsTowardAlertingAcrossReboot() throws {
        // Reboot: monotonic clock RESET to a small value; only the wall leg shows expiry.
        let persisted = EscalationState(
            state: .COUNTDOWN, enteredAt: ts(2000),
            deadlineAt: Timestamp(monotonicMs: 32000, wallMs: 1_784_073_632_000),
            seq: 2, fsmVersion: fsmVersion)
        let bootNow = Timestamp(monotonicMs: 500, wallMs: 1_784_073_700_000)
        let outcome = try EscalationFSM.recover(persisted: persisted, now: bootNow)
        XCTAssertEqual(outcome?.newState.state, .ALERTING,
                       "a deadline that expired while the device was dead must fail toward alerting (SRS-504)")
    }

    func testJournalRecordsCarrySequenceAndVersion() throws {
        let s = EscalationFSM.initialState(at: ts(0))
        let r = try EscalationFSM.transition(s, input: .suspect, now: ts(1000))
        XCTAssertEqual(r.record.from, .IDLE)
        XCTAssertEqual(r.record.to, .SUSPECTED)
        XCTAssertEqual(r.record.seq, 1)
        XCTAssertEqual(r.record.fsmVersion, fsmVersion)
    }
}
