import SwiftUI

/// De lijst achter de chip "Trainingen".
struct SavedWorkoutsSheet: View {
    @EnvironmentObject private var engine: WorkoutEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if engine.saved.isEmpty {
                    ContentUnavailableView(
                        "Nog geen trainingen",
                        systemImage: "circle.dashed",
                        description: Text("Tik op “Bewaren” om de huidige instellingen te houden.")
                    )
                } else {
                    List {
                        ForEach(engine.saved) { entry in
                            Button {
                                engine.load(entry)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.name)
                                        .rondoLabel(10)
                                        .foregroundStyle(RondoTheme.bone.opacity(0.5))
                                    Text(entry.workout.summary)
                                        .font(RondoType.body(13))
                                        .foregroundStyle(RondoTheme.bone)
                                }
                                .padding(.vertical, 2)
                            }
                            .listRowBackground(RondoTheme.inkRaised)
                        }
                        .onDelete { offsets in
                            for entry in offsets.map({ engine.saved[$0] }) {
                                engine.delete(entry)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(RondoTheme.ink)
            .navigationTitle("Trainingen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sluiten") { dismiss() }
                        .foregroundStyle(RondoTheme.bone.opacity(0.7))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(RondoTheme.ink)
        .preferredColorScheme(.dark)
    }
}
