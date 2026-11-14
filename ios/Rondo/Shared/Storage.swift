import Foundation

/// Bewaart instellingen tussen sessies. Beide platforms hebben hun eigen
/// `UserDefaults`; `SyncLink` houdt ze gelijk zolang de tegenhanger bereikbaar
/// is, en als dat niet zo is blijft elke kant met zijn eigen laatste stand
/// werken.
enum Storage {
    private static let workoutKey = "rondo.workout.v1"
    private static let savedKey = "rondo.saved.v1"
    private static let soundKey = "rondo.sound.v1"

    static func loadWorkout() -> Workout {
        guard let data = UserDefaults.standard.data(forKey: workoutKey),
              let value = try? JSONDecoder().decode(Workout.self, from: data) else { return Workout() }
        return value
    }

    static func save(_ workout: Workout) {
        guard let data = try? JSONEncoder().encode(workout) else { return }
        UserDefaults.standard.set(data, forKey: workoutKey)
    }

    static func loadSaved() -> [SavedWorkout] {
        guard let data = UserDefaults.standard.data(forKey: savedKey),
              let value = try? JSONDecoder().decode([SavedWorkout].self, from: data) else { return [] }
        return value
    }

    static func saveSaved(_ list: [SavedWorkout]) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        UserDefaults.standard.set(data, forKey: savedKey)
    }

    static func loadSound() -> Bool {
        UserDefaults.standard.object(forKey: soundKey) as? Bool ?? true
    }

    static func saveSound(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: soundKey)
    }
}
