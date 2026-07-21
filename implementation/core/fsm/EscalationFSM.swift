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

// 0.1.0 → 0.2.0: recovery/expiry semantics changed (isExpired monotonic-only; recover()
// fails toward alerting pending RFC-008). Version identifiers exist to distinguish behavior —
// same-stamp/different-behavior would be a forensic ambiguity (D20/ADR-015; PR #1 delta review).
public let fsmVersion = "fsm-0.2.0-phase0"

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

    /// Within a single boot the MONOTONIC clock is authoritative and never jumps — so
    /// expiry is monotonic-only. (AUDIT-002 Story-2 fix: the previous `|| wallMs >= …` OR-rule
    /// let a forward wall-clock jump — NTP correction, DST, a user changing the clock — fire a
    /// live countdown EARLY and alert family before the wearer's cancel window elapsed (H-02).)
    /// Cross-boot expiry is NOT decided here: a persisted monotonic deadline is meaningless after
    /// a reboot (the clock resets), and the wall clock is unreliable too (dead-RTC → 1970). That
    /// case belongs to `recover()`, and doing it *correctly* needs a persisted boot-session id —
    /// see RFC-008. This function is only ever valid for same-boot comparisons.
    public static func isExpired(deadline: Timestamp, now: Timestamp) -> Bool {
        now.monotonicMs >= deadline.monotonicMs
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

    /// Reboot recovery (D11; SRS-501/504). CONSERVATIVE INTERIM pending RFC-008.
    ///
    /// A device that reboots inside a live COUNTDOWN or ALERTING cannot know how much time
    /// really elapsed while it was dead: the monotonic clock reset to ~0, and the wall clock may
    /// be wrong (dead-RTC boots at 1970). AUDIT-002 proved that the old wall-clock fallback
    /// silently resumed such states and let the deadline become *unexpirable for days* — a
    /// missed real emergency (H-01). Neither clock can decide this correctly without a persisted
    /// boot-session identifier that distinguishes "this deadline is from a previous boot" from
    /// "this deadline is later this same boot" — that is RFC-008.
    ///
    /// Until RFC-008 lands, safety decides the tie: recovering a timed state **fails toward
    /// alerting** (H-01 miss ≫ H-02 false alarm; SRS-504). The cost — a false alarm if the device
    /// merely restarted the app mid-countdown with the wearer fine — is accepted, documented
    /// debt (Notebook-A), to be removed by RFC-008's boot-session id (which will restore accurate
    /// resume-vs-escalate). A safety countdown that survives a reboot must never be able to
    /// silently NOT fire.
    public static func recover(persisted: EscalationState, now: Timestamp) throws -> TransitionResult? {
        switch persisted.state {
        case .COUNTDOWN, .ALERTING:
            // Cannot prove the wearer is safe across a reboot → escalate. `deadlineExpired` is a
            // legal edge from both COUNTDOWN (→ALERTING) and ALERTING (→ESCALATING). The persisted
            // deadline is treated as reached because we cannot prove it was not.
            let reached = Timestamp(monotonicMs: max(now.monotonicMs, persisted.deadlineAt?.monotonicMs ?? now.monotonicMs),
                                    wallMs: now.wallMs)
            return try transition(persisted, input: .deadlineExpired, now: reached)
        default:
            return nil // stable states resume as-is
        }
    }
}
