import Foundation

/// De signalen die de klok afgeeft. Wat ermee gebeurt, hangt van het platform
/// af: op de iPhone piepjes door je muziek heen, op de Watch tikken op je arm.
enum Cue {
    case tick, work, rest, reset, done

    static func forPhase(_ phase: Phase) -> Cue {
        switch phase {
        case .work: return .work
        case .rest: return .rest
        case .reset: return .reset
        }
    }
}

/// Eén afnemer van die signalen. `WorkoutEngine` kent alleen dit.
///
/// Niet actor-geïsoleerd: de engine is `@MainActor` en roept de afnemers
/// altijd vanaf de hoofdthread aan, zodat dit protocol op beide platforms
/// zonder isolatie-acrobatiek te implementeren is.
protocol CueSink: AnyObject {
    var isEnabled: Bool { get set }
    /// Een training begint of hervat.
    func beginSession()
    /// Pauze, herstellen of einde.
    func endSession()
    func play(_ cue: Cue)
}
