import SwiftUI

/// Bewerkt één instelling, in dezelfde opzet als de webversie: min en plus
/// rond de waarde, zes vaste keuzes eronder, en onderaan Annuleren en Klaar.
struct EditFieldSheet: View {
    let field: Workout.Field
    @State private var draft: Int
    @State private var height: CGFloat = 360
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    private var palette: RondoPalette { RondoPalette(scheme) }

    init(field: Workout.Field, value: Int, onSave: @escaping (Int) -> Void) {
        self.field = field
        self.onSave = onSave
        _draft = State(initialValue: value)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(field.title)
                .font(RondoType.body(11, weight: 700))
                .tracking(0.16 * 11)
                .textCase(.uppercase)
                .foregroundStyle(palette.mute)
                .padding(.bottom, 20)

            if let note = field.note {
                Text(note)
                    .font(RondoType.body(13))
                    .lineSpacing(3)
                    .foregroundStyle(palette.mute)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, -12)
                    .padding(.bottom, 18)
            }

            HStack(spacing: 10) {
                nudge("–", by: -1, label: "Minder")
                Text(text(for: draft))
                    .rondoNumerals(46)
                    .foregroundStyle(palette.fg)
                    .frame(maxWidth: .infinity)
                nudge("+", by: 1, label: "Meer")
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(presets, id: \.self) { value in
                    Button {
                        draft = value
                    } label: {
                        Text(text(for: value))
                            .font(RondoType.body(14, weight: 600).monospacedDigit())
                            .foregroundStyle(draft == value ? palette.bg : palette.fg)
                            .frame(maxWidth: .infinity, minHeight: 46)
                    }
                    .buttonStyle(OutlineButtonStyle(shape: Capsule(),
                                                    border: draft == value ? palette.fg : palette.hair,
                                                    pressed: draft == value ? palette.fg : palette.raised,
                                                    fill: draft == value ? palette.fg : .clear))
                }
            }
            .padding(.top, 20)

            HStack(spacing: 10) {
                LinkButton(title: "Annuleren", color: palette.mute) { dismiss() }

                Button {
                    onSave(min(field.range.upperBound, max(field.range.lowerBound, draft)))
                    dismiss()
                } label: {
                    Text("Klaar")
                        .font(RondoType.body(12, weight: 700))
                        .tracking(0.14 * 12)
                        .textCase(.uppercase)
                        .foregroundStyle(palette.bg)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Capsule().fill(palette.fg))
                        .contentShape(Capsule())
                }
                .buttonStyle(QuietButtonStyle())
            }
            .padding(.top, 22)
        }
        .padding(.top, 22)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .fixedSize(horizontal: false, vertical: true)
        // De sheet is precies zo hoog als zijn inhoud.
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(height)])
        .presentationCornerRadius(20)
        .presentationDragIndicator(.hidden)
        .presentationBackground(palette.bg)
    }

    private func nudge(_ symbol: String, by direction: Int, label: String) -> some View {
        Button {
            draft = min(field.range.upperBound, max(field.range.lowerBound, draft + direction * field.step))
        } label: {
            Text(symbol)
                .font(RondoType.body(24))
                .foregroundStyle(palette.fg)
                .frame(width: 56, height: 56)
        }
        .buttonStyle(OutlineButtonStyle(shape: Circle(), border: palette.hair, pressed: palette.raised))
        .accessibilityLabel(label)
    }

    private var presets: [Int] {
        switch field {
        case .work: return [20, 30, 40, 45, 60, 90]
        case .rest: return [0, 15, 20, 30, 45, 60]
        case .resetRound: return [0, 30, 60, 90, 120, 180]
        case .exercises: return [1, 2, 3, 4, 5, 6]
        case .rounds: return [3, 4, 5, 6, 8, 10]
        }
    }

    private func text(for value: Int) -> String {
        field.isDuration ? Workout.clock(value) : "\(value)"
    }
}
