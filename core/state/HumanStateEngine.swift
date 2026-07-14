import Foundation

// Human State Engine — Phase-0 SKELETON of the Phase-2 subsystem (ADR-102/ADR-006).
// Exists so the pipeline spine (IF-INT-01 → IF-INT-02) is real and the harness can drive
// it end-to-end. The genuine fusion/calibration work is Phase 2; nothing here pretends
// otherwise. Deterministic fold: no clock, no randomness, unknown-first (D13).

public struct HumanStateEngine: Sendable {
    public private(set) var current: HumanState

    public init(wearerId: UUID, at: Timestamp) {
        self.current = .allUnknown(wearerId: wearerId, at: at)
    }

    /// Fold one piece of admitted Evidence into the canonical state (IF-INT-02 producer).
    /// v0 rules only — enough to exercise the spine, honest about what it doesn't know:
    /// a gap marker degrades the relevant channel back to `unknown` (VV-105's direction:
    /// missing modalities widen uncertainty, never silently hold "normal").
    public mutating func ingest(_ evidence: SensorEvidence) -> HumanState {
        var next = current
        next.at = evidence.measuredAt
        next.contributingEvidence.append(evidence.id)

        switch evidence.kind {
        case .gap:
            // Loss is never silent (D13): all inferred channels widen to unknown.
            next.posture = .unknown
            next.motion = .unknown
            next.physiology = HumanState.Physiology()
            next.confidence = .coldStart(0.0)
        case .platformFall:
            // Platform detection is evidence, never authority (ADR-004): it informs
            // posture/motion; Risk decides what it means.
            next.posture = .lying
            next.motion = .still
            next.confidence = evidence.confidence
        case .motion:
            if let level = evidence.values.first {
                next.motion = level > 0.5 ? .active : .still
            } else {
                next.motion = .unknown
            }
            next.confidence = evidence.confidence
        case .heartRate:
            next.physiology.hr = evidence.values.first
            next.confidence = evidence.confidence
        default:
            // Other kinds don't move the v0 state; they still appear in contributingEvidence.
            break
        }

        current = next
        return next
    }
}
