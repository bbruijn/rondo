import SwiftUI

/// Bewerkt één instelling. Duren krijgen minuut- en secondewielen, tellers één
/// wiel — de standaardmanier van iOS, prettiger dan plus/min-knoppen.
struct EditFieldSheet: View {
    let field: Workout.Field
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var count: Int
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    init(field: Workout.Field, value: Int, onSave: @escaping (Int) -> Void) {
        self.field = field
        self.onSave = onSave
        _minutes = State(initialValue: value / 60)
        _seconds = State(initialValue: value % 60)
        _count = State(initialValue: value)
    }

    private var result: Int { field.isDuration ? minutes * 60 + seconds : count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text(field.title)
                    .rondoLabel(11)
                    .foregroundStyle(RondoTheme.bone.opacity(0.5))

                if let note = field.note {
                    Text(note)
                        .font(.system(size: 13))
                        .foregroundStyle(RondoTheme.bone.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.top, -10)
                        .padding(.horizontal, 8)
                }

                if field.isDuration {
                    HStack(spacing: 0) {
                        wheel(range: 0...60, selection: $minutes, unit: "min")
                        wheel(range: 0...59, selection: $seconds, unit: "sec")
                    }
                    .frame(height: 170)
                } else {
                    Picker(field.title, selection: $count) {
                        ForEach(Array(field.range), id: \.self) { value in
                            Text(field == .rounds ? "\(value)×" : "\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 170)
                }

                if !presets.isEmpty {
                    presetRow
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            .background(RondoTheme.ink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") { dismiss() }
                        .foregroundStyle(RondoTheme.bone.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klaar") {
                        onSave(max(field.range.lowerBound, min(field.range.upperBound, result)))
                        dismiss()
                    }
                    .foregroundStyle(RondoTheme.puls)
                }
            }
        }
        .presentationDetents([.height(400)])
        .presentationBackground(RondoTheme.ink)
        .preferredColorScheme(.dark)
    }

    private func wheel(range: ClosedRange<Int>, selection: Binding<Int>, unit: String) -> some View {
        HStack(spacing: 4) {
            Picker(unit, selection: selection) {
                ForEach(Array(range), id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Text(unit)
                .rondoLabel(9)
                .foregroundStyle(RondoTheme.bone.opacity(0.45))
        }
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

    private var presetRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { value in
                    Button {
                        if field.isDuration {
                            minutes = value / 60
                            seconds = value % 60
                        } else {
                            count = value
                        }
                    } label: {
                        Text(label(for: value))
                            .font(RondoType.numerals(14))
                            .foregroundStyle(result == value ? RondoTheme.ink : RondoTheme.bone)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule().fill(result == value ? RondoTheme.bone : Color.clear)
                            )
                            .overlay(Capsule().strokeBorder(RondoTheme.bone.opacity(0.16), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func label(for value: Int) -> String {
        switch field {
        case .rounds: return "\(value)×"
        case .exercises: return "\(value)"
        default: return Workout.clock(value)
        }
    }
}
