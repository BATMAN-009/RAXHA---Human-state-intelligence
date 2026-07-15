import Foundation
import RaxhaCore

// Replay runner — drives one trace through the pipeline spine:
//   SensorEvidence → HumanStateEngine → RiskEngineV0 → PolicyEngineV0 → EscalationFSM
//   (IF-INT-01)      (IF-INT-02)        (IF-INT-03)     (IF-INT-04)      (IF-INT-05)
// Produces the decision log (hashed by VV-101) and the typed object streams
// (validated by VV-110). Write-ahead discipline is structural: the journal record is
// appended to the log BEFORE any effect entry for the same transition.

struct DecisionLogEntry: Codable {
    var at: Timestamp
    var kind: String // "humanState" | "risk" | "decision" | "transition"
    var humanState: HumanState? = nil
    var risk: RiskScore? = nil
    var decision: PolicyDecision? = nil
    var transition: TransitionRecord? = nil
}

struct ReplayResult {
    var traceId: String
    var log: [DecisionLogEntry] = []
    var evidence: [SensorEvidence] = []
    var humanStates: [HumanState] = []
    var risks: [RiskScore] = []
    var decisions: [PolicyDecision] = []
    var journal: [TransitionRecord] = []
    var incidents: [Incident] = []
    var finalEscalation: EscalationState
}

enum ReplayError: Error {
    case unsupportedTraceSchema(String)
    case fsmFault(String)
}

enum ReplayRunner {

    static func run(_ trace: Trace) throws -> ReplayResult {
        guard trace.schemaVersion == "trace-v0.1" else {
            throw ReplayError.unsupportedTraceSchema(trace.schemaVersion)
        }

        let t0 = trace.events.first?.at ?? Timestamp(monotonicMs: 0, wallMs: 0)
        var hse = HumanStateEngine(wearerId: trace.wearerId, at: t0)
        var ids = DeterministicIdSource(traceId: trace.traceId)
        var escalation = EscalationFSM.initialState(at: t0)
        var result = ReplayResult(traceId: trace.traceId, finalEscalation: escalation)

        // IF-INT-05's contract object is Incident + EscalationState (12 line 23). The replay
        // constructs a real Incident so VV-110 validates it — not just the journal records.
        var openIncident: Incident? = nil

        func applyTransition(_ input: FSMInput, at: Timestamp) throws {
            let r = try EscalationFSM.transition(escalation, input: input, now: at)
            // Write-ahead: journal record first, always (ADR-105).
            result.journal.append(r.record)
            result.log.append(DecisionLogEntry(at: at, kind: "transition", transition: r.record))
            escalation = r.newState
            if var inc = openIncident {
                inc.escalation = escalation
                inc.timeline.append(.transition(escalation))
                if escalation.state == .RESOLVED {
                    inc.resolvedAt = at
                    if case .resolve(let res) = input { inc.resolution = res }
                    result.incidents.append(inc)
                    openIncident = nil
                } else {
                    openIncident = inc
                }
            }
        }

        // Stable order: ties on monotonicMs keep original file order (offset), so the decision
        // log — and therefore its hash — is fully specified even for same-timestamp events.
        // Without this, Swift's non-stable sort could reorder ties across builds and silently
        // flip a life-critical outcome (wearer-cancel honored vs. family alerted).
        let events = trace.events.enumerated()
            .sorted { a, b in
                a.element.at.monotonicMs != b.element.at.monotonicMs
                    ? a.element.at.monotonicMs < b.element.at.monotonicMs
                    : a.offset < b.offset
            }
            .map { $0.element }
        for event in events {
            // Persisted deadlines fire on time passing, before the event is processed.
            if let d = escalation.deadlineAt,
               (escalation.state == .COUNTDOWN || escalation.state == .ALERTING),
               EscalationFSM.isExpired(deadline: d, now: event.at)
            {
                try applyTransition(.deadlineExpired, at: event.at)
                // COUNTDOWN expiry lands in ALERTING with an ack deadline that may ALSO
                // already be past at this event's time; the next loop events handle it.
            }

            if let evidence = event.evidence {
                result.evidence.append(evidence)
                let state = hse.ingest(evidence)
                result.humanStates.append(state)
                result.log.append(DecisionLogEntry(at: event.at, kind: "humanState", humanState: state))

                let candidates = evidence.kind == .platformFall ? [evidence] : []
                let risk = RiskEngineV0.evaluate(id: ids.nextId(), state: state,
                                                 candidates: candidates, at: event.at)
                result.risks.append(risk)
                result.log.append(DecisionLogEntry(at: event.at, kind: "risk", risk: risk))

                let decision = PolicyEngineV0.decide(id: ids.nextId(), risk: risk, at: event.at)
                result.decisions.append(decision)
                result.log.append(DecisionLogEntry(at: event.at, kind: "decision", decision: decision))

                if decision.action == .countdown, escalation.state == .IDLE {
                    try applyTransition(.suspect, at: event.at)
                    // Open the Incident at SUSPECTED (before the countdown transition mutates it).
                    openIncident = Incident(
                        id: ids.nextId(), wearerId: trace.wearerId, openedAt: event.at,
                        cause: decision.id, escalation: escalation, stateSnapshot: state)
                    try applyTransition(.startCountdown(seconds: decision.countdownSeconds ?? 0), at: event.at)
                }
            }

            if let action = event.action {
                switch action {
                case "wearerCancel":
                    if escalation.state == .COUNTDOWN {
                        try applyTransition(.wearerCancel, at: event.at)
                    }
                case "contactAck":
                    if escalation.state == .ALERTING {
                        try applyTransition(.contactAcknowledged, at: event.at)
                    }
                case "resolveContactAck":
                    if escalation.state == .ACKNOWLEDGED || escalation.state == .ESCALATING {
                        try applyTransition(.resolve(.contactAck), at: event.at)
                    }
                case "tick":
                    break // time advance only; deadline check already ran above
                default:
                    throw ReplayError.fsmFault("unknown trace action '\(action)'")
                }
            }
        }

        // An incident that never resolved (trace ends in COUNTDOWN/ALERTING/ESCALATING) is still
        // a real object crossing IF-INT-05 — record it so VV-110 validates it too.
        if let inc = openIncident { result.incidents.append(inc) }

        result.finalEscalation = escalation
        return result
    }

    /// Canonical serialization of the decision log: sorted keys, no ambient values —
    /// the byte stream VV-101 hashes.
    static func canonicalLogData(_ result: ReplayResult) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(result.log)
    }
}
