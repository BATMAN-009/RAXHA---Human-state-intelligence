import Foundation

// 08B Part B: `Contact` — a CONSENTED responder: `accepted` is required before any
// Alert may target them (PDR-011).

public struct Contact: Codable, Hashable, Sendable {
    public enum Consent: String, Codable, Sendable {
        case invited, accepted, declined
    }

    public struct Channel: Codable, Hashable, Sendable {
        public var rung: AlertEnvelope.Rung
        public var address: String
        public var criticalAlertCapable: Bool
        public init(rung: AlertEnvelope.Rung, address: String, criticalAlertCapable: Bool) {
            self.rung = rung
            self.address = address
            self.criticalAlertCapable = criticalAlertCapable
        }
    }

    public struct QuietHours: Codable, Hashable, Sendable {
        public var startMinuteOfDay: Int
        public var endMinuteOfDay: Int
        public init(startMinuteOfDay: Int, endMinuteOfDay: Int) {
            self.startMinuteOfDay = startMinuteOfDay
            self.endMinuteOfDay = endMinuteOfDay
        }
    }

    public var id: UUID
    public var wearerId: UUID
    public var name: String
    public var relationship: String
    public var channels: [Channel]
    public var escalationOrder: Int
    public var consent: Consent
    public var quietHours: QuietHours?

    public init(id: UUID, wearerId: UUID, name: String, relationship: String, channels: [Channel],
                escalationOrder: Int, consent: Consent, quietHours: QuietHours? = nil) {
        self.id = id
        self.wearerId = wearerId
        self.name = name
        self.relationship = relationship
        self.channels = channels
        self.escalationOrder = escalationOrder
        self.consent = consent
        self.quietHours = quietHours
    }
}

// 08B Part B: `DeviceCoverage` — the Coverage KPI's substrate (D09); every `degraded`
// is attributable to a `cause`, which is what the coaching hooks (D14) act on.
// NOTE: RFC-006 proposes adding `platformFallDetectionEnabled` (+ watch-model capability).
// It is PROPOSED, not founder-decided — the field is deliberately absent until then.

public struct DeviceCoverage: Codable, Hashable, Sendable {
    public enum Protection: String, Codable, Sendable {
        case protected, degraded, unprotected
    }

    public enum WornState: String, Codable, Sendable {
        case worn, off, unknown
    }

    public enum LinkState: String, Codable, Sendable {
        case up, down, unknown
    }

    public enum PermissionState: String, Codable, Sendable {
        case granted, denied, unknown
    }

    public struct Battery: Codable, Hashable, Sendable {
        public var watch: Double?
        public var phone: Double?
        public init(watch: Double? = nil, phone: Double? = nil) {
            self.watch = watch
            self.phone = phone
        }
    }

    public struct Links: Codable, Hashable, Sendable {
        public var watchPhone: LinkState
        public var phoneCloud: LinkState
        public init(watchPhone: LinkState, phoneCloud: LinkState) {
            self.watchPhone = watchPhone
            self.phoneCloud = phoneCloud
        }
    }

    public struct Permissions: Codable, Hashable, Sendable {
        public var location: PermissionState
        public var notifications: PermissionState
        public var health: PermissionState
        public var motion: PermissionState
        public init(location: PermissionState, notifications: PermissionState,
                    health: PermissionState, motion: PermissionState) {
            self.location = location
            self.notifications = notifications
            self.health = health
            self.motion = motion
        }
    }

    public struct Gap: Codable, Hashable, Sendable {
        public var from: Timestamp
        public var to: Timestamp
        public var cause: String
        public init(from: Timestamp, to: Timestamp, cause: String) {
            self.from = from
            self.to = to
            self.cause = cause
        }
    }

    public var wearerId: UUID
    public var at: Timestamp
    public var protection: Protection
    public var wornState: WornState
    public var battery: Battery
    public var links: Links
    public var permissions: Permissions
    public var gaps: [Gap]

    public init(wearerId: UUID, at: Timestamp, protection: Protection, wornState: WornState,
                battery: Battery, links: Links, permissions: Permissions, gaps: [Gap]) {
        self.wearerId = wearerId
        self.at = at
        self.protection = protection
        self.wornState = wornState
        self.battery = battery
        self.links = links
        self.permissions = permissions
        self.gaps = gaps
    }
}
