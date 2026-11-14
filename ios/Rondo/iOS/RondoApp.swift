import SwiftUI

@main
struct RondoApp: App {
    @StateObject private var engine = WorkoutEngine()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(engine)
                .preferredColorScheme(.dark)
        }
    }
}

/// Hangt de piepjes en de koppeling met de Watch aan de engine. Beide zijn
/// optioneel: zonder Watch werkt de app gewoon, zonder audio ook.
private struct RootView: View {
    @EnvironmentObject private var engine: WorkoutEngine
    @State private var wired = false

    var body: some View {
        TimerScreen()
            .task {
                guard !wired else { return }
                wired = true
                engine.add(sink: AudioCoach())
                engine.connect(SyncLink.shared)
            }
    }
}
