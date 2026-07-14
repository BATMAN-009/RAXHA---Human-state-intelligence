import Foundation

// Policy Engine v0 — Phase-0 STUB of the Phase-4 subsystem (ADR-104/ADR-014).
//
// ⚠ Deliberately incomplete, per the RFC register's sequencing note: RFC-001 (v1 detection
// re-scope) and RFC-002 (coordinate AFTER Apple's native fall flow) shape the fall path's
// ENTRY CONDITIONS and are founder-pending. This stub therefore encodes only the trivially
// safe mapping needed to drive the harness spine — it makes no RFC-committing choices.
// The veto-contract suite (VV-102, the L1 release gate) arrives with the real engine in
// Phase 4; RFC-003's confidence-floor rule is likewise pending and NOT encoded.
//
// Deterministic and replayable (ADR-008): identical inputs ⇒ identical decision, forever.
// No LLM anywhere in this path, ever (D03).

public enum PolicyEngineV0 {
    public static let policyVersion = "policy-v0.0.1-phase0-stub"
    /// Provisional wearer-cancel window for countdown decisions (real value: Phase 4 + RFC-002).
    public static let defaultCountdownSeconds = 30

    public static func decide(id: UUID, risk: RiskScore, at: Timestamp) -> PolicyDecision {
        let action: PolicyDecision.Action
        var countdownSeconds: Int? = nil
        let rationale: String
        let trustCost: PolicyDecision.TrustCost

        switch risk.severity {
        case .critical, .high:
            action = .countdown
            countdownSeconds = defaultCountdownSeconds
            rationale = "Possible fall detected and the wearer appears unresponsive; starting a cancellable countdown before alerting family."
            trustCost = .high
        case .moderate:
            action = .checkIn
            rationale = "Something unusual was noticed; asking the wearer to confirm they are okay."
            trustCost = .low
        case .low:
            action = .none
            rationale = "Nothing unusual observed."
            trustCost = .none
        }

        return PolicyDecision(
            id: id, riskRef: risk.id, action: action, countdownSeconds: countdownSeconds,
            rationale: rationale, policyVersion: policyVersion, decidedAt: at, trustCost: trustCost)
    }
}
