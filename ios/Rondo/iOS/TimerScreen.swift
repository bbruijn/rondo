import SwiftUI

/// De iPhone, in dezelfde opzet als de webversie: de ring is de held én de
/// startknop, het cijfer staat erin, de instellingen staan er als één rij
/// chips onder, en de vier acties zijn tekstlinks. De maten komen uit
/// `web/styles.css`.
///
/// Het scherm volgt de lichte of donkere modus van het toestel: inkt of papier.
struct TimerScreen: View {
    @EnvironmentObject private var engine: WorkoutEngine
    @Environment(\.colorScheme) private var scheme

    @State private var editing: Workout.Field?
    @State private var showingSaved = false
    @State private var justSaved = false

    private var palette: RondoPalette { RondoPalette(scheme) }
    private var accent: RondoAccent { palette.accent(for: engine.phase) }

    var body: some View {
        GeometryReader { geometry in
            // De ring: 88% van de breedte, maar nooit meer dan het halve scherm.
            let side = min(geometry.size.width * 0.88, geometry.size.height * 0.5, 430)

            ScrollView {
                VStack(spacing: 22) {
                    score(side: side, width: geometry.size.width)
                    chips
                    bar
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(palette.bg.ignoresSafeArea())
        .sheet(item: $editing) { field in
            EditFieldSheet(field: field, value: engine.workout[field]) { engine.workout[field] = $0 }
        }
        .sheet(isPresented: $showingSaved) {
            SavedWorkoutsSheet()
        }
    }

    // MARK: - De partituur

    private func score(side: CGFloat, width: CGFloat) -> some View {
        Button {
            engine.toggle()
        } label: {
            ZStack {
                RondoDial(segments: engine.program,
                          index: engine.index,
                          fraction: engine.segmentFraction,
                          isFinished: engine.isFinished,
                          hasStarted: engine.hasStarted,
                          accent: accent,
                          ink: palette.fg,
                          radiusFraction: 132.0 / 320.0)

                VStack(spacing: 2) {
                    Text(engine.shortHeadline)
                        .rondoLabel(clamp(width * 0.029, 11, 13))
                        .foregroundStyle(accent.color)

                    Text(engine.clock)
                        .rondoNumerals(clamp(width * 0.17, 54, 96))
                        .foregroundStyle(palette.fg)
                        .padding(.top, 2)
                        .padding(.bottom, 4)

                    Text(engine.subtitle)
                        .rondoCaption(clamp(width * 0.026, 10, 12))
                        .foregroundStyle(palette.mute)

                    // Verdwijnt zodra de training loopt, net als op het web.
                    Text("Tik om te starten")
                        .rondoCaption(11)
                        .foregroundStyle(palette.mute)
                        .padding(.top, 14)
                        .opacity(engine.hasStarted ? 0 : 1)
                }
                .padding(.horizontal, side * 0.16)
            }
            .frame(width: side, height: side)
            .contentShape(Circle())
            .animation(.easeInOut(duration: 0.4), value: accent)
        }
        .buttonStyle(QuietButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(engine.isRunning ? "Pauzeren" : "Starten")
        .accessibilityValue("\(engine.shortHeadline), \(engine.clock)")
    }

    // MARK: - Instelchips

    private var chips: some View {
        HStack(spacing: 6) {
            ForEach(Workout.Field.allCases.filter { $0.isRelevant(in: engine.workout) }) { field in
                Button {
                    editing = field
                } label: {
                    VStack(spacing: 1) {
                        Text(field.shortTitle)
                            .font(RondoType.body(8.5, weight: 700))
                            .tracking(0.04 * 8.5)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .foregroundStyle(palette.mute)
                        Text(display(field))
                            .font(RondoType.numerals(15, width: 80))
                            .lineLimit(1)
                            .foregroundStyle(palette.fg)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 9)
                    .padding(.horizontal, 4)
                }
                .buttonStyle(OutlineButtonStyle(shape: Capsule(),
                                                border: isActive(field) ? accent.color : palette.hair,
                                                pressed: palette.raised))
                .animation(.easeInOut(duration: 0.2), value: isActive(field))
            }
        }
        .frame(maxWidth: 460)
    }

    // MARK: - Onderbalk

    private var bar: some View {
        HStack(spacing: 2) {
            LinkButton(title: "Bewaard", color: palette.mute) {
                showingSaved = true
            }
            LinkButton(title: justSaved ? "Bewaard" : "Opslaan", color: palette.mute) {
                engine.saveCurrent()
                justSaved = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { justSaved = false }
            }
            LinkButton(title: "Herstel", color: palette.mute) {
                engine.reset()
            }
            LinkButton(title: "Geluid", color: palette.mute) {
                engine.isSoundOn.toggle()
            }
            .opacity(engine.isSoundOn ? 1 : 0.45)
            .accessibilityValue(engine.isSoundOn ? "Aan" : "Uit")
        }
    }

    private func display(_ field: Workout.Field) -> String {
        field.isDuration ? Workout.clock(engine.workout[field]) : "\(engine.workout[field])"
    }

    /// Markeert de chip van de fase die nu loopt.
    private func isActive(_ field: Workout.Field) -> Bool {
        guard engine.isRunning, let phase = engine.phase else { return false }
        switch (phase, field) {
        case (.work, .work), (.rest, .rest), (.reset, .resetRound): return true
        default: return false
        }
    }

    private func clamp(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
        min(high, max(low, value))
    }
}

// MARK: - Onderdelen

/// Een tekstlink zoals in de onderbalk en de sheets van de webversie.
struct LinkButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RondoType.body(10, weight: 700))
                .tracking(0.1 * 10)
                .textCase(.uppercase)
                .lineLimit(1)
                .foregroundStyle(color)
                .padding(.horizontal, 7)
                .padding(.vertical, 9)
                // Het raakvlak is hoger dan de tekst, zodat je niet hoeft te mikken.
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(QuietButtonStyle())
    }
}

/// Een knop zonder eigen drukeffect: de ring mag niet dimmen als je hem aanraakt.
struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

/// Een omlijnde knop — chip, preset of rij — die alleen bij aanraken een vlak
/// krijgt. Vlakken dragen nooit een accent.
struct OutlineButtonStyle<S: InsettableShape>: ButtonStyle {
    let shape: S
    let border: Color
    let pressed: Color
    var fill: Color = .clear

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(shape.fill(configuration.isPressed ? pressed : fill))
            .overlay(shape.strokeBorder(border, lineWidth: 1))
            .contentShape(shape)
    }
}

#if DEBUG
#Preview {
    TimerScreen()
        .environmentObject(WorkoutEngine())
}
#endif
