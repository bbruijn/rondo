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
            // Een paar punten lucht, zodat de ring de rand van het glas niet raakt.
            let side = min(geometry.size.width, geometry.size.height) - 8
            // Een fractie onder het midden, zodat de ring vrij blijft van de
            // klok en het telefoonicoon in de statusbalk rechtsboven.
            let drop = geometry.size.height * 0.025
            // De Watch is altijd inkt; het accent volgt de fase.
            let palette = RondoPalette(.dark)
            let accent = palette.accent(for: engine.phase)

            ZStack {
                RondoDial(segments: engine.program,
                          index: engine.index,
                          fraction: engine.segmentFraction,
                          isFinished: engine.isFinished,
                          hasStarted: engine.hasStarted,
                          accent: accent,
                          ink: palette.fg,
                          weight: 1.1)
                    .frame(width: side, height: side)
                    .animation(.easeInOut(duration: 0.4), value: engine.phase)

                VStack(spacing: 1) {
                    Text(engine.shortHeadline)
                        .rondoLabel(max(8, side * 0.062))
                        .foregroundStyle(accent.color)

                    Text(engine.clock)
                        .rondoNumerals(side * 0.30)
                        .foregroundStyle(palette.fg)

                    Text(engine.hasStarted ? "\(engine.current?.round ?? 1)/\(engine.workout.rounds)" : Workout.clock(engine.total))
                        .rondoLabel(max(7, side * 0.052))
                        .foregroundStyle(RondoTheme.bone.opacity(0.45))
                }
                .padding(.horizontal, side * 0.22)
                .animation(.easeInOut(duration: 0.4), value: engine.phase)
            }
            .offset(y: drop)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .onTapGesture { engine.toggle() }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(engine.headline), \(engine.clock)")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(engine.isRunning ? String(localized: "Tap to pause") : String(localized: "Tap to start"))
        }
        // Het hele scherm, ook achter de klok: alleen zo vult de ring het
        // scherm. De klok en de paginastipjes vallen in de hoeken buiten de
        // ring.
        .ignoresSafeArea()
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
                    Text("Sound")
                        .rondoLabel(9)
                        .foregroundStyle(RondoTheme.bone.opacity(0.6))
                }
                .tint(RondoTheme.puls)

                Button {
                    engine.reset()
                } label: {
                    Text("Reset")
                        .rondoLabel(9)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Text("Total \(Workout.clock(engine.total))")
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
