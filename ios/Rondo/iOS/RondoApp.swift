import SwiftUI

@main
struct RondoApp: App {
    @StateObject private var engine = WorkoutEngine()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(engine)
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
            .onAppear {
                // Synchrone sluiting: erft de hoofdactor van `body`. Een
                // `.task` is `@Sendable` en zou hier `await` vragen.
                guard !wired else { return }
                wired = true
                engine.add(sink: AudioCoach())
                engine.connect(SyncLink.shared)
            }
    }
}
