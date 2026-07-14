import Foundation

// 08B Part B: `EscalationState`. Transitions are write-ahead durable and reboot-recoverable
// (D11); `deadlineAt` is a PERSISTED TIMESTAMP, never an in-memory timer.

public struct EscalationState: Codable, Hashable, Sendable {
    public enum State: String, Codable, Sendable {
        case IDLE, SUSPECTED, COUNTDOWN, ALERTING, ACKNOWLEDGED, ESCALATING, RESOLVED
    }

    public var state: State
    public var enteredAt: Timestamp
    public var deadlineAt: Timestamp?
    public var seq: Int
    public var fsmVersion: String

    public init(state: State, enteredAt: Timestamp, deadlineAt: Timestamp? = nil, seq: Int, fsmVersion: String) {
        self.state = state
        self.enteredAt = enteredAt
        self.deadlineAt = deadlineAt
        self.seq = seq
        self.fsmVersion = fsmVersion
    }
}

// 08B Part B: `Incident`. Location embeds ONLY with uncertainty + age (D15).
// `user_cancel`/`false_alarm_confirmed` resolutions feed shadow-mode labels (D08/D20).

public struct Incident: Codable, Hashable, Sendable {
    public enum Resolution: String, Codable, Sendable {
        case userCancel = "user_cancel"
        case contactAck = "contact_ack"
        case services
        case timeoutEscalated = "timeout_escalated"
        case falseAlarmConfirmed = "false_alarm_confirmed"
    }

    public struct Location: Codable, Hashable, Sendable {
        public var lat: Double
        public var lon: Double
        public var uncertaintyMeters: Double
        public var ageSeconds: Double
        public var source: String
        public init(lat: Double, lon: Double, uncertaintyMeters: Double, ageSeconds: Double, source: String) {
            self.lat = lat
            self.lon = lon
            self.uncertaintyMeters = uncertaintyMeters
            self.ageSeconds = ageSeconds
            self.source = source
        }
    }

    public enum TimelineEntry: Codable, Hashable, Sendable {
        case transition(EscalationState)
        case alert(alertId: UUID, at: Timestamp)
        case ack(contactId: UUID, at: Timestamp)
    }

    /// `id` is the idempotency key (D06).
    public var id: UUID
    public var wearerId: UUID
    public var openedAt: Timestamp
    /// The PolicyDecision.id that opened this Incident.
    public var cause: UUID
    public var escalation: EscalationState
    public var stateSnapshot: HumanState
    public var location: Location?
    public var timeline: [TimelineEntry]
    public var resolvedAt: Timestamp?
    public var resolution: Resolution?

    public init(id: UUID, wearerId: UUID, openedAt: Timestamp, cause: UUID,
                escalation: EscalationState, stateSnapshot: HumanState, location: Location? = nil,
                timeline: [TimelineEntry] = [], resolvedAt: Timestamp? = nil, resolution: Resolution? = nil) {
        self.id = id
        self.wearerId = wearerId
        self.openedAt = openedAt
        self.cause = cause
        self.escalation = escalation
        self.stateSnapshot = stateSnapshot
        self.location = location
        self.timeline = timeline
        self.resolvedAt = resolvedAt
        self.resolution = resolution
    }
}
