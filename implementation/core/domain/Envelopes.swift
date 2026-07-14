import Foundation

// 08B Part B: `EventEnvelope` — the durable inter-tier message; all consumers are
// idempotent (D06). Payload carries events/features only — NEVER raw waveforms (D05).

public struct EventEnvelope: Codable, Hashable, Sendable {
    /// Dedup key (D06).
    public var eventId: UUID
    public var incidentId: UUID?
    public var seq: Int
    public var type: String
    /// Structured payload — events/features only, never raw waveforms (D05).
    public var payload: JSONValue
    public var createdAt: Timestamp
    public var deviceId: String
    public var fsmVersion: String
    public var ackedAt: Timestamp?

    public init(eventId: UUID, incidentId: UUID? = nil, seq: Int, type: String, payload: JSONValue,
                createdAt: Timestamp, deviceId: String, fsmVersion: String, ackedAt: Timestamp? = nil) {
        self.eventId = eventId
        self.incidentId = incidentId
        self.seq = seq
        self.type = type
        self.payload = payload
        self.createdAt = createdAt
        self.deviceId = deviceId
        self.fsmVersion = fsmVersion
        self.ackedAt = ackedAt
    }
}

// 08B Part B: `AlertEnvelope` — one Alert per contact per rung; `locationShare` is
// token-scoped and expiring (D21); unacknowledged ⇒ the ladder climbs (D06).

public struct AlertEnvelope: Codable, Hashable, Sendable {
    public enum Rung: String, Codable, Sendable {
        case push, sms, voice
    }

    public struct LocationShare: Codable, Hashable, Sendable {
        public var token: String
        public var expiresAt: Timestamp
        public init(token: String, expiresAt: Timestamp) {
            self.token = token
            self.expiresAt = expiresAt
        }
    }

    public var alertId: UUID
    public var incidentId: UUID
    public var contactId: UUID
    public var rung: Rung
    /// Responder vocabulary (D15).
    public var summary: String
    public var locationShare: LocationShare?
    public var responderCardRef: String?
    public var sentAt: Timestamp
    public var deliveryReceipt: Timestamp?
    public var acknowledgedAt: Timestamp?

    public init(alertId: UUID, incidentId: UUID, contactId: UUID, rung: Rung, summary: String,
                locationShare: LocationShare? = nil, responderCardRef: String? = nil,
                sentAt: Timestamp, deliveryReceipt: Timestamp? = nil, acknowledgedAt: Timestamp? = nil) {
        self.alertId = alertId
        self.incidentId = incidentId
        self.contactId = contactId
        self.rung = rung
        self.summary = summary
        self.locationShare = locationShare
        self.responderCardRef = responderCardRef
        self.sentAt = sentAt
        self.deliveryReceipt = deliveryReceipt
        self.acknowledgedAt = acknowledgedAt
    }
}

/// Minimal deterministic JSON value type for envelope payloads
/// (dictionary keys sort on encode, so hashes are stable — ADR-109).
public indirect enum JSONValue: Codable, Hashable, Sendable {
    case null
    case bool(Bool)
    case int(Int64)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int64.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let a = try? container.decode([JSONValue].self) {
            self = .array(a)
        } else if let o = try? container.decode([String: JSONValue].self) {
            self = .object(o)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let b): try container.encode(b)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .string(let s): try container.encode(s)
        case .array(let a): try container.encode(a)
        case .object(let o): try container.encode(o)
        }
    }
}
