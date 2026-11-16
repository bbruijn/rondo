import Foundation

/// De vijf instelbare waarden van een training.
///
/// Overgenomen uit V1 — inclusief de programmaregel, die hier letterlijk
/// gelijk moet blijven: 60 s werk / 90 s rust / 1 oefening / 8 rondes is
/// precies 18:30, omdat de laatste rust vervalt.
struct Workout: Codable, Equatable {
    var work = 60
    var rest = 90
    var exercises = 1
    var rounds = 8
    var resetRound = 0

    enum Field: String, CaseIterable, Identifiable, Codable {
        case work, rest, exercises, rounds, resetRound

        var id: String { rawValue }

        var title: String {
            switch self {
            case .work: return "Arbeid"
            case .rest: return "Rust"
            case .exercises: return "Per ronde"
            case .rounds: return "Rondes"
            case .resetRound: return "Pauze"
            }
        }

        /// Korte vorm voor de chips op de iPhone en de regels op de Watch.
        var shortTitle: String {
            switch self {
            case .work: return "Arbeid"
            case .rest: return "Rust"
            case .exercises: return "Per ronde"
            case .rounds: return "Rondes"
            case .resetRound: return "Pauze"
            }
        }

        /// Eén regel uitleg onder de titel van de bewerk-sheet. Alleen waar
        /// de instelling zichzelf niet uitlegt.
        var note: String? {
            switch self {
            case .exercises: return "Hoeveel arbeid-rust-paren er in één ronde zitten."
            case .resetRound: return "Extra rust ná een hele ronde, bovenop de gewone rust."
            default: return nil
            }
        }

        /// Pauze heeft pas betekenis vanaf twee paren per ronde. Staat hij op
        /// nul, dan verbergen we hem; staat er tijd op, dan blijft hij staan —
        /// anders verstop je een instelling die het programma nog verandert.
        func isRelevant(in workout: Workout) -> Bool {
            guard self == .resetRound else { return true }
            return workout.exercises > 1 || workout.resetRound > 0
        }

        /// Duurvelden krijgen minuut/seconde-wielen, tellers één wiel.
        var isDuration: Bool {
            switch self {
            case .work, .rest, .resetRound: return true
            case .exercises, .rounds: return false
            }
        }

        var range: ClosedRange<Int> {
            switch self {
            case .work: return 1...3600
            case .rest: return 0...3600
            case .resetRound: return 0...1800
            case .exercises: return 1...50
            case .rounds: return 1...99
            }
        }

        var step: Int {
            switch self {
            case .work, .rest, .resetRound: return 5
            case .exercises, .rounds: return 1
            }
        }
    }

    subscript(field: Field) -> Int {
        get {
            switch field {
            case .work: return work
            case .rest: return rest
            case .exercises: return exercises
            case .rounds: return rounds
            case .resetRound: return resetRound
            }
        }
        set {
            let value = min(field.range.upperBound, max(field.range.lowerBound, newValue))
            switch field {
            case .work: work = value
            case .rest: rest = value
            case .exercises: exercises = value
            case .rounds: rounds = value
            case .resetRound: resetRound = value
            }
        }
    }

    /// Het volledige programma: per ronde elke oefening werk + rust, tussen
    /// rondes de reset. De laatste rust vervalt — de training eindigt na het
    /// laatste werkinterval.
    var segments: [Segment] {
        var result: [Segment] = []
        for round in 1...max(1, rounds) {
            for exercise in 1...max(1, exercises) {
                result.append(Segment(phase: .work, duration: work, round: round, exercise: exercise))
                if rest > 0 {
                    result.append(Segment(phase: .rest, duration: rest, round: round, exercise: exercise))
                }
            }
            if round < rounds, resetRound > 0 {
                result.append(Segment(phase: .reset, duration: resetRound, round: round, exercise: max(1, exercises)))
            }
        }
        while let last = result.last, last.phase != .work { result.removeLast() }
        return result
    }

    var totalDuration: Int { segments.reduce(0) { $0 + $1.duration } }

    /// Eén regel voor de lijst met bewaarde trainingen, in dezelfde vorm als
    /// de webversie: arbeid / rust · oefeningen · rondes · totaal.
    var summary: String {
        "\(Self.clock(work)) / \(Self.clock(rest)) · \(exercises) oef. · \(rounds)× · \(Self.clock(totalDuration))"
    }

    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        let rest = s % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, rest)
            : String(format: "%02d:%02d", minutes, rest)
    }
}

enum Phase: String, Codable, CaseIterable {
    case work, rest, reset

    /// De toon is Nederlands en kort; geen uitroeptekens.
    var label: String {
        switch self {
        case .work: return "Arbeid"
        case .rest: return "Rust"
        case .reset: return "Pauze"
        }
    }

    /// Korter label voor de Watch, waar de breedte telt.
    var shortLabel: String {
        switch self {
        case .work: return "Arbeid"
        case .rest: return "Rust"
        case .reset: return "Pauze"
        }
    }
}

struct Segment: Equatable {
    let phase: Phase
    let duration: Int
    let round: Int
    let exercise: Int
}

/// Een opgeslagen training in "Trainingen".
struct SavedWorkout: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var workout: Workout
}
