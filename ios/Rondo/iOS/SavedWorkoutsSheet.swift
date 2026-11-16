import SwiftUI

/// De lijst achter de link "Bewaard", in dezelfde opzet als de webversie.
/// Tik op een rij om hem te laden; houd een rij ingedrukt om hem te verwijderen.
struct SavedWorkoutsSheet: View {
    @EnvironmentObject private var engine: WorkoutEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    /// Hoogte van de rijen samen, en van de hele sheet: de sheet is precies
    /// zo hoog als zijn inhoud, en de lijst scrolt pas vanaf een half scherm.
    @State private var listHeight: CGFloat = 0
    @State private var height: CGFloat = 220

    private var palette: RondoPalette { RondoPalette(scheme) }

    var body: some View {
        VStack(spacing: 0) {
            Text("Bewaarde trainingen")
                .font(RondoType.body(11, weight: 700))
                .tracking(0.16 * 11)
                .textCase(.uppercase)
                .foregroundStyle(palette.mute)
                .padding(.bottom, 20)

            if engine.saved.isEmpty {
                Text("Nog niets bewaard. Tik op “Opslaan” om deze training te bewaren.")
                    .font(RondoType.body(13))
                    .foregroundStyle(palette.mute)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 7) {
                        ForEach(engine.saved) { entry in
                            row(entry)
                        }
                    }
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { listHeight = $0 }
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(height: min(max(listHeight, 1), 380))
            }

            HStack {
                LinkButton(title: "Sluiten", color: palette.mute) { dismiss() }
                Spacer()
            }
            .padding(.top, 10)
        }
        .padding(.top, 22)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(height)])
        .presentationCornerRadius(20)
        .presentationDragIndicator(.hidden)
        .presentationBackground(palette.bg)
    }

    private func row(_ entry: SavedWorkout) -> some View {
        Button {
            engine.load(entry)
            dismiss()
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(RondoType.body(14, weight: 600))
                        .foregroundStyle(palette.fg)
                    Text(entry.workout.summary)
                        .font(RondoType.body(12).monospacedDigit())
                        .foregroundStyle(palette.mute)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                Text("Laad")
                    .font(RondoType.body(11, weight: 700))
                    .tracking(0.12 * 11)
                    .foregroundStyle(palette.mute)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(OutlineButtonStyle(shape: RoundedRectangle(cornerRadius: 14, style: .continuous),
                                        border: palette.hair,
                                        pressed: palette.raised))
        .contextMenu {
            Button(role: .destructive) {
                engine.delete(entry)
            } label: {
                Label("Verwijder", systemImage: "trash")
            }
        }
    }
}
