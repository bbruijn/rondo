import SwiftUI

/// De iPhone: de ring is de held, het cijfer staat erin, de instellingen staan
/// er als chips onder. Geen rijen met vlakken in accentkleur — de huisstijl
/// houdt accenten bij de ring, het cijfer en één label.
struct TimerScreen: View {
    @EnvironmentObject private var engine: WorkoutEngine
    @ObservedObject private var link = SyncLink.shared

    @State private var editing: Workout.Field?
    @State private var showingSaved = false
    @State private var justSaved = false

    private var accent: RondoAccent { RondoTheme.accentParts(for: engine.phase) }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    header
                    hero
                        .padding(.top, 4)
                    meta
                        .padding(.top, 14)
                    controls
                        .padding(.top, 22)
                    chips
                        .padding(.top, 26)
                    footer
                        .padding(.top, 18)
                }
                .padding(.bottom, 28)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(RondoTheme.ink.ignoresSafeArea())
        .sheet(item: $editing) { field in
            EditFieldSheet(field: field, value: engine.workout[field]) { engine.workout[field] = $0 }
        }
        .sheet(isPresented: $showingSaved) {
            SavedWorkoutsSheet()
        }
    }

    // MARK: - Kop

    private var header: some View {
        HStack(spacing: 10) {
            Text("Rondo")
                .rondoLabel(13)
                .foregroundStyle(RondoTheme.bone)

            Spacer(minLength: 8)

            if link.isAvailable {
                Text(link.isReachable ? "Watch" : "Watch ·")
                    .rondoLabel(10)
                    .foregroundStyle(RondoTheme.bone.opacity(link.isReachable ? 0.7 : 0.35))
            }

            Button {
                engine.isSoundOn.toggle()
            } label: {
                Image(systemName: engine.isSoundOn ? "speaker.wave.2" : "speaker.slash")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(RondoTheme.bone.opacity(engine.isSoundOn ? 0.8 : 0.4))
                    .frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(RondoTheme.bone.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.isSoundOn ? "Geluid uitzetten" : "Geluid aanzetten")
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
    }

    // MARK: - De ring

    private var hero: some View {
        ZStack {
            RondoDial(segments: engine.program,
                      index: engine.index,
                      fraction: engine.segmentFraction,
                      isRunning: engine.isRunning,
                      isFinished: engine.isFinished,
                      hasStarted: engine.hasStarted,
                      accent: accent)
                .animation(.easeInOut(duration: 0.4), value: engine.phase)

            VStack(spacing: 8) {
                Text(engine.headline)
                    .rondoLabel(12)
                    .foregroundStyle(accent.color)

                Text(engine.clock)
                    .rondoNumerals(78)
                    .foregroundStyle(accent.color)

                Text(engine.subtitle)
                    .font(RondoType.body(12))
                    .foregroundStyle(RondoTheme.bone.opacity(0.5))
                    .lineLimit(1)
            }
            .padding(.horizontal, 54)
            .animation(.easeInOut(duration: 0.4), value: engine.phase)
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(engine.headline), \(engine.clock)")
    }

    private var meta: some View {
        let dim = engine.hasStarted ? 0.6 : 0.3
        return HStack(spacing: 18) {
            Text(engine.roundText)
                .rondoLabel(10)
                .foregroundStyle(RondoTheme.bone.opacity(dim))
            Text(engine.exerciseText)
                .rondoLabel(10)
                .foregroundStyle(RondoTheme.bone.opacity(dim))
        }
    }

    // MARK: - Bediening

    private var controls: some View {
        HStack(spacing: 14) {
            GhostButton(title: "Herstellen", dimmed: !engine.hasStarted) {
                engine.reset()
            }

            Button {
                engine.toggle()
            } label: {
                ZStack {
                    Circle().strokeBorder(accent.color, lineWidth: 2)
                    Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(accent.color)
                }
                .frame(width: 76, height: 76)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.4), value: engine.phase)
            .accessibilityLabel(engine.isRunning ? "Pauzeren" : "Starten")

            GhostButton(title: justSaved ? "Bewaard" : "Bewaren") {
                engine.saveCurrent()
                justSaved = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { justSaved = false }
            }
        }
        .padding(.horizontal, 22)
    }

    // MARK: - Instellingen als chips

    private var chips: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(Workout.Field.allCases.filter { $0.isRelevant(in: engine.workout) }) { field in
                    Button {
                        editing = field
                    } label: {
                        SettingChip(title: field.shortTitle,
                                    value: display(field),
                                    accent: accent.color,
                                    isActive: isActive(field))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showingSaved = true
                } label: {
                    SettingChip(title: "Trainingen",
                                value: engine.saved.isEmpty ? "—" : "\(engine.saved.count)",
                                accent: accent.color,
                                isActive: false)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
    }

    private var footer: some View {
        Text("Geluid mengt door je muziek heen en loopt door met het scherm op slot.")
            .font(RondoType.body(11))
            .foregroundStyle(RondoTheme.bone.opacity(0.4))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 36)
    }

    private func display(_ field: Workout.Field) -> String {
        switch field {
        case .rounds: return "\(engine.workout.rounds)×"
        case .exercises: return "\(engine.workout.exercises)"
        default: return Workout.clock(engine.workout[field])
        }
    }

    /// Markeert de chip van de fase die nu loopt.
    private func isActive(_ field: Workout.Field) -> Bool {
        guard engine.isRunning, let phase = engine.phase else { return false }
        switch (phase, field) {
        case (.work, .work), (.rest, .rest), (.reset, .resetRound): return true
        default: return false
        }
    }
}

// MARK: - Onderdelen

/// Compacte chip: klein label, groot cijfer, geen gekleurd vlak.
struct SettingChip: View {
    let title: String
    let value: String
    let accent: Color
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .rondoLabel(9)
                .foregroundStyle(RondoTheme.bone.opacity(0.45))
            Text(value)
                .font(RondoType.numerals(20))
                .tracking(RondoType.numeralTracking(20))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(isActive ? accent : RondoTheme.bone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(RondoTheme.inkRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isActive ? accent : RondoTheme.bone.opacity(0.08), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.4), value: isActive)
    }
}

struct GhostButton: View {
    let title: String
    var dimmed = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .rondoLabel(10)
                .foregroundStyle(RondoTheme.bone.opacity(dimmed ? 0.35 : 0.8))
                .frame(maxWidth: .infinity, minHeight: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(RondoTheme.bone.opacity(0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    TimerScreen()
        .environmentObject(WorkoutEngine())
        .preferredColorScheme(.dark)
}
#endif
