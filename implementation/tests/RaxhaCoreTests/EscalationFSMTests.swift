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

    // CONSERVATIVE INTERIM (AUDIT-002 Story-2, pending RFC-008): recover() cannot know how much
    // time really elapsed across a reboot, so it fails toward alerting rather than risk silent
    // non-protection (H-01). Both a still-ahead deadline and an across-reboot one escalate.
    func testRecoveryOfTimedStateFailsTowardAlerting() throws {
        // "Unexpired by monotonic" — but recover cannot trust that across a reboot, so it escalates.
        let ahead = EscalationState(state: .COUNTDOWN, enteredAt: ts(2000), deadlineAt: ts(32000),
                                    seq: 2, fsmVersion: fsmVersion)
        XCTAssertEqual(try EscalationFSM.recover(persisted: ahead, now: ts(10000))?.newState.state, .ALERTING,
                       "a recovered COUNTDOWN must fail toward alerting — safety cannot be assumed across a reboot (RFC-008)")

        // Dead-RTC reboot (the AUDIT-002 CRITICAL): wall reset to ~1970, monotonic reset. The old
        // code silently resumed and NEVER fired. It must now escalate regardless of clock state.
        let deadRTC = EscalationState(
            state: .COUNTDOWN, enteredAt: ts(2000),
            deadlineAt: Timestamp(monotonicMs: 32000, wallMs: 1_784_073_632_000),
            seq: 2, fsmVersion: fsmVersion)
        let bootNow1970 = Timestamp(monotonicMs: 5000, wallMs: 5000) // RTC reset to epoch
        XCTAssertEqual(try EscalationFSM.recover(persisted: deadRTC, now: bootNow1970)?.newState.state, .ALERTING,
                       "dead-RTC reboot must not leave a countdown unexpirable — it must escalate (SRS-504)")

        // Stable states resume as-is.
        let acked = EscalationState(state: .ACKNOWLEDGED, enteredAt: ts(2000), seq: 4, fsmVersion: fsmVersion)
        XCTAssertNil(try EscalationFSM.recover(persisted: acked, now: ts(10000)))
    }

    func testForwardWallJumpDoesNotFireCountdownEarly() throws {
        // H-02 fix: a forward wall-clock jump must NOT expire a live countdown before its
        // monotonic deadline. Deadline is at monotonic 32000; now is monotonic 10000 (not reached)
        // but the wall clock has jumped far past. Expiry must be refused.
        let s = EscalationState(state: .COUNTDOWN, enteredAt: ts(2000),
                                deadlineAt: Timestamp(monotonicMs: 32000, wallMs: 1_784_073_632_000),
                                seq: 2, fsmVersion: fsmVersion)
        let wallJumped = Timestamp(monotonicMs: 10000, wallMs: 9_999_999_999_999)
        XCTAssertFalse(EscalationFSM.isExpired(deadline: s.deadlineAt!, now: wallJumped),
                       "a forward wall-clock jump must not expire a monotonic deadline early (H-02)")
        XCTAssertThrowsError(try EscalationFSM.transition(s, input: .deadlineExpired, now: wallJumped)) {
            XCTAssertEqual($0 as? TransitionError, .deadlineNotReached)
        }
    }

    func testSaturatingAddDoesNotTrapOnOverflow() {
        // A schema-valid but extreme timestamp must not crash the safety core.
        let extreme = Timestamp(monotonicMs: Int64.max - 5, wallMs: Int64.max - 5)
        let result = extreme.adding(milliseconds: 1000)
        XCTAssertEqual(result.monotonicMs, Int64.max, "overflow must saturate, not trap")
        XCTAssertEqual(result.wallMs, Int64.max)
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
