import Foundation

// Ports (ADR-011; names from B13/12): every I/O crosses one of these boundaries.
// The pure core defines the protocols; adapters (mobile/, backend/, harness/) implement
// them. The core itself NEVER touches a platform API, a real clock, or an entropy source.

/// Time enters the core only through this port (ADR-109 determinism).
public protocol Clock: Sendable {
    func now() -> Timestamp
}

/// ID generation enters the core only through this port. Not in the original B13/12 port
/// list — added because VV-101 (bit-identical decisions) is unachievable if the core calls
/// UUID(): random IDs would differ every run. Adapters may use real UUIDs; the harness
/// derives them deterministically from (traceId, counter).
public protocol IdSource: Sendable {
    mutating func nextId() -> UUID
}

/// Motion evidence stream (accelerometer/gyro-derived, platform detections).
public protocol MotionSource {
    func evidence() -> [SensorEvidence]
}

/// Physiological evidence stream (HR/HRV etc.).
public protocol VitalsSource {
    func evidence() -> [SensorEvidence]
}

/// Location evidence — always with uncertainty + age attached at source (D13/D15).
public protocol LocationSource {
    func evidence() -> [SensorEvidence]
}

/// Watch ↔ phone durable link (IF-PLT-04): EventEnvelopes, at-least-once → exactly-once-effect.
public protocol PeerLink {
    func send(_ envelope: EventEnvelope) throws
}

/// Outbound alert delivery ladder (push/sms/voice).
public protocol AlertTransport {
    func deliver(_ alert: AlertEnvelope) throws
}

/// Durable store for the incident journal (IF-INT-05): write-ahead, boot-readable (ADR-105).
public protocol HealthRecordStore {
    func append(_ record: TransitionRecord) throws
    func latestState() throws -> EscalationState?
}

/// On-device model inference (never an LLM in the decision path — D03/ADR-008).
public protocol Inference {
    func score(features: [Double]) throws -> Double
}
