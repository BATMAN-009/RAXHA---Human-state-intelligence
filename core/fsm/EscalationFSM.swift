import Foundation

// Escalation FSM — exactly the Blueprint A6 state machine, nothing more:
//
//   IDLE → SUSPECTED → COUNTDOWN → ALERTING → ACKNOWLEDGED
//      ▲       │(reject)     │(cancel)     │             │
//      └───────┴─────────────┘             └─▶ ESCALATING ┴─▶ RESOLVED
//
// Every transition is durable, idempotent, reboot-recoverable (D11, ADR-105):
// the FSM is a PURE function that RETURNS a journal record; the caller must persist
// the record BEFORE applying any effect (write-ahead). `deadlineAt` is a persisted
// timestamp, never an in-memory timer.
//
// Deliberately NOT here (RFC-001/RFC-002 pending founder decision): the fall path's
// ENTRY CONDITIONS — what causes `suspect` and how RAXHA coordinates with Apple's
// native fall flow. Those live in Policy/Response (Phases 4–5). This machine only
// defines what the states ARE and how they may legally move.

public let fsmVersion = "fsm-0.1.0-phase0"

public enum FSMInput: Codable, Hashable, Sendable {
    /// A PolicyDecision chose to act; Incident opens in SUSPECTED.
    case suspect
    /// Suspicion withdrawn before commitment (SUSPECTED → IDLE).
    case reject
    /// Begin the wearer-cancellable countdown. 0 seconds is legal (immediate paths, A5).
    case startCountdown(seconds: Int)
    /// Wearer cancelled during COUNTDOWN (→ IDLE; feeds shadow labels, D08).
    case wearerCancel
    /// The persisted deadline passed (COUNTDOWN → ALERTING, or ALERTING → ESCALATING).
    case deadlineExpired
    /// A contact acknowledged (ALERTING → ACKNOWLEDGED).
    case contactAcknowledged
    /// Terminal close with an explicit resolution (ACKNOWLEDGED/ESCALATING → RESOLVED).
    case resolve(Incident.Resolution)
}

/// The write-ahead journal record. Persist FIRST, then apply effects (ADR-105).
public struct TransitionRecord: Codable, Hashable, Sendable {
    public var from: EscalationState.State
    public var to: EscalationState.State
    public var input: FSMInput
    public var at: Timestamp
    public var seq: Int
    public var fsmVersion: String
}

public enum TransitionError: Error, Equatable, Sendable {
    /// The input is not a legal edge from the current state (Blueprint A6).
    case illegalTransition(from: EscalationState.State, input: String)
    /// `deadlineExpired` claimed but `now` is before the persisted deadline.
    case deadlineNotReached
}

public struct TransitionResult: Sendable {
    public var newState: EscalationState
    public var record: TransitionRecord
}

public enum EscalationFSM {

    /// How long ALERTING waits for an acknowledgment before the ladder climbs.
    /// Provisional Phase-0 value; the real value is a Policy/Response concern (Phase 4–5).
    public static let defaultAckDeadlineMs: Int64 = 120_000

    public static func initialState(at: Timestamp) -> EscalationState {
        EscalationState(state: .IDLE, enteredAt: at, deadlineAt: nil, seq: 0, fsmVersion: fsmVersion)
    }

    /// A deadline is expired if EITHER clock leg has passed it. Monotonic governs within a
    /// boot; the wall leg catches deadlines that expired across a reboot (monotonic clocks
    /// reset at boot, so the monotonic comparison is meaningless there). A forward wall-clock
    /// jump can expire a deadline early — that errs toward alerting, the direction doctrine
    /// requires (SRS-504).
    public static func isExpired(deadline: Timestamp, now: Timestamp) -> Bool {
        now.monotonicMs >= deadline.monotonicMs || now.wallMs >= deadline.wallMs
    }

    /// Pure transition: (state, input, now) → new state + journal record. No I/O, no clock,
    /// no randomness — identical inputs yield identical outputs, forever (ADR-008/109).
    public static func transition(_ current: EscalationState, input: FSMInput, now: Timestamp)
        throws -> TransitionResult
    {
        let next: EscalationState.State
        var deadline: Timestamp? = nil

        switch (current.state, input) {
        case (.IDLE, .suspect):
            next = .SUSPECTED
        case (.SUSPECTED, .reject):
            next = .IDLE
        case (.SUSPECTED, .startCountdown(let seconds)):
            next = .COUNTDOWN
            deadline = now.adding(milliseconds: Int64(seconds) * 1000)
        case (.COUNTDOWN, .wearerCancel):
            next = .IDLE
        case (.COUNTDOWN, .deadlineExpired):
            guard let d = current.deadlineAt, isExpired(deadline: d, now: now) else {
                throw TransitionError.deadlineNotReached
            }
            next = .ALERTING
            deadline = now.adding(milliseconds: defaultAckDeadlineMs)
        case (.ALERTING, .contactAcknowledged):
            next = .ACKNOWLEDGED
        case (.ALERTING, .deadlineExpired):
            guard let d = current.deadlineAt, isExpired(deadline: d, now: now) else {
                throw TransitionError.deadlineNotReached
            }
            next = .ESCALATING
        case (.ACKNOWLEDGED, .resolve), (.ESCALATING, .resolve):
            next = .RESOLVED
        default:
            throw TransitionError.illegalTransition(from: current.state, input: String(describing: input))
        }

        let newState = EscalationState(
            state: next, enteredAt: now, deadlineAt: deadline,
            seq: current.seq + 1, fsmVersion: fsmVersion)
        let record = TransitionRecord(
            from: current.state, to: next, input: input, at: now,
            seq: newState.seq, fsmVersion: fsmVersion)
        return TransitionResult(newState: newState, record: record)
    }

    /// Reboot recovery (D11; SRS-501/504; the VV-106 behavior, unit-testable now):
    /// resume from the persisted journal state. A deadline that expired while the device
    /// was dead FAILS TOWARD ALERTING — never silently back to IDLE.
    public static func recover(persisted: EscalationState, now: Timestamp) throws -> TransitionResult? {
        switch persisted.state {
        case .COUNTDOWN, .ALERTING:
            if let d = persisted.deadlineAt, isExpired(deadline: d, now: now) {
                return try transition(persisted, input: .deadlineExpired, now: now)
            }
            return nil // deadline still ahead: resume with the same persisted deadline
        default:
            return nil // stable states resume as-is
        }
    }
}
