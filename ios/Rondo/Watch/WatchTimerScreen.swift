import SwiftUI

/// De Watch: de ring vult het scherm, het cijfer staat erin, één label erboven.
/// Tik op de ring om te starten of te pauzeren; de tweede pagina heeft de
/// instellingen, zodat de Watch ook zonder telefoon volledig bruikbaar is.
struct WatchTimerScreen: View {
    @EnvironmentObject private var engine: WorkoutEngine

    var body: some View {
        TabView {
            dialPage
            settingsPage
        }
        .tabViewStyle(.verticalPage)
        .background(RondoTheme.ink.ignoresSafeArea())
    }

    // MARK: - Pagina 1: de ring

    private var dialPage: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let accent = RondoTheme.accentParts(for: engine.phase)

            ZStack {
                RondoDial(segments: engine.program,
                          index: engine.index,
                          fraction: engine.segmentFraction,
                          isRunning: engine.isRunning,
                          isFinished: engine.isFinished,
                          hasStarted: engine.hasStarted,
                          accent: accent,
                          weight: 1.1)
                    .animation(.easeInOut(duration: 0.4), value: engine.phase)

                VStack(spacing: 1) {
                    Text(engine.shortHeadline)
                        .rondoLabel(max(8, side * 0.062))
                        .foregroundStyle(accent.color)

                    Text(engine.clock)
                        .rondoNumerals(side * 0.30)
                        .foregroundStyle(accent.color)

                    Text(engine.hasStarted ? "\(engine.current?.round ?? 1)/\(engine.workout.rounds)" : Workout.clock(engine.total))
                        .rondoLabel(max(7, side * 0.052))
                        .foregroundStyle(RondoTheme.bone.opacity(0.45))
                }
                .padding(.horizontal, side * 0.22)
                .animation(.easeInOut(duration: 0.4), value: engine.phase)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .onTapGesture { engine.toggle() }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(engine.headline), \(engine.clock)")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(engine.isRunning ? "Tik om te pauzeren" : "Tik om te starten")
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Pagina 2: instellingen

    private var settingsPage: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(Workout.Field.allCases) { field in
                    Stepper(value: binding(field), in: field.range, step: field.step) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(field.shortTitle)
                                .rondoLabel(9)
                                .foregroundStyle(RondoTheme.bone.opacity(0.45))
                            Text(value(field))
                                .font(RondoType.numerals(17))
                                .foregroundStyle(RondoTheme.bone)
                        }
                    }
                }

                Toggle(isOn: Binding(get: { engine.isSoundOn },
                                     set: { engine.isSoundOn = $0 })) {
                    Text("Geluid")
                        .rondoLabel(9)
                        .foregroundStyle(RondoTheme.bone.opacity(0.6))
                }
                .tint(RondoTheme.puls)

                Button {
                    engine.reset()
                } label: {
                    Text("Herstellen")
                        .rondoLabel(9)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Text("Totaal \(Workout.clock(engine.total))")
                    .rondoLabel(9)
                    .foregroundStyle(RondoTheme.bone.opacity(0.4))
                    .padding(.top, 2)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)
        }
    }

    private func binding(_ field: Workout.Field) -> Binding<Int> {
        Binding(get: { engine.workout[field] },
                set: { engine.workout[field] = $0 })
    }

    private func value(_ field: Workout.Field) -> String {
        switch field {
        case .rounds: return "\(engine.workout.rounds)×"
        case .exercises: return "\(engine.workout.exercises)"
        default: return Workout.clock(engine.workout[field])
        }
    }
}

#if DEBUG
#Preview {
    WatchTimerScreen()
        .environmentObject(WorkoutEngine())
}
#endif
