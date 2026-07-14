import Foundation

// 08B Part B: `RiskScore`. `modelVersion` + `thresholdVersion` are MANDATORY — both are
// governed safety artifacts (D20/ADR-015), so every score is traceable to the exact
// artifacts that produced it.

public struct RiskScore: Codable, Hashable, Sendable {
    public enum Severity: String, Codable, Sendable {
        case low, moderate, high, critical
    }

    public var id: UUID
    public var wearerId: UUID
    public var at: Timestamp
    /// Calibrated 0...1 (provenance in `confidence`).
    public var value: Double
    public var severity: Severity
    /// Reference to the HumanState consumed (its `at`; HumanState carries no id in 08B).
    public var humanStateRef: Timestamp
    /// Candidate SensorEvidence ids awaiting scoring.
    public var candidates: [UUID]
    /// Human-readable contributing factors.
    public var rationale: [String]
    public var modelVersion: String
    public var thresholdVersion: String
    public var confidence: Confidence

    public init(id: UUID, wearerId: UUID, at: Timestamp, value: Double, severity: Severity,
                humanStateRef: Timestamp, candidates: [UUID], rationale: [String],
                modelVersion: String, thresholdVersion: String, confidence: Confidence) {
        self.id = id
        self.wearerId = wearerId
        self.at = at
        self.value = value
        self.severity = severity
        self.humanStateRef = humanStateRef
        self.candidates = candidates
        self.rationale = rationale
        self.modelVersion = modelVersion
        self.thresholdVersion = thresholdVersion
        self.confidence = confidence
    }
}

// 08B Part B: `PolicyDecision`. Deterministic and replayable (ADR-008):
// identical inputs ⇒ identical decision, forever.
public struct PolicyDecision: Codable, Hashable, Sendable {
    public enum Action: String, Codable, Sendable {
        case none
        case observe
        case checkIn = "check_in"
        case countdown
        case alert
        case escalate
    }

    public enum TrustCost: String, Codable, Sendable {
        case none, low, high
    }

    public var id: UUID
    public var riskRef: UUID
    public var action: Action
    public var countdownSeconds: Int?
    /// Responder vocabulary (D15) — plain words a family member understands.
    public var rationale: String
    public var policyVersion: String
    public var decidedAt: Timestamp
    public var trustCost: TrustCost

    public init(id: UUID, riskRef: UUID, action: Action, countdownSeconds: Int? = nil,
                rationale: String, policyVersion: String, decidedAt: Timestamp, trustCost: TrustCost) {
        self.id = id
        self.riskRef = riskRef
        self.action = action
        self.countdownSeconds = countdownSeconds
        self.rationale = rationale
        self.policyVersion = policyVersion
        self.decidedAt = decidedAt
        self.trustCost = trustCost
    }
}
