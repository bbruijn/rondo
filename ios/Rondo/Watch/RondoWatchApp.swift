import SwiftUI

@main
struct RondoWatchApp: App {
    @StateObject private var engine = WorkoutEngine()
    @StateObject private var runtime = ExtendedRuntime()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(engine)
                .environmentObject(runtime)
        }
    }
}

/// Hangt de haptiek en de koppeling met de iPhone aan de engine, en houdt de
/// uitgebreide runtime-sessie gelijk met de klok.
private struct WatchRootView: View {
    @EnvironmentObject private var engine: WorkoutEngine
    @EnvironmentObject private var runtime: ExtendedRuntime
    @State private var wired = false

    var body: some View {
        WatchTimerScreen()
            .task {
                guard !wired else { return }
                wired = true
                engine.add(sink: WatchHaptics())
                engine.connect(SyncLink.shared)
            }
            .onChange(of: engine.isRunning) { _, running in
                if running {
                    runtime.start()
                } else {
                    runtime.stop()
                }
            }
    }
}
