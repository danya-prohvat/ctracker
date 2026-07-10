import SwiftUI
import SwiftData

/// Edit the quantity of an existing diary entry (spec §5 — tap a row to change it).
/// Nutrition recomputes from the frozen per-100 snapshot; history stays consistent.
/// Deleting removes only this snapshot — the source product is never touched.
struct QuantityEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [UserSettings]

    let entry: DiaryEntry

    var body: some View {
        NavigationStack {
            QuantityEditor(
                name: entry.productName,
                wasScanned: entry.wasScanned,
                basis: entry.basis,
                per100Calories: entry.per100Calories,
                per100Protein: entry.per100Protein,
                per100Fat: entry.per100Fat,
                per100Carbs: entry.per100Carbs,
                unitSystem: settingsList.first?.unitSystem ?? .metric,
                initialCanonical: entry.quantity,
                title: "Edit entry",
                ctaTitle: "Save changes",
                onBack: { dismiss() },     // prototype: Back closes the sheet in edit mode
                onClose: { dismiss() },
                onDelete: deleteEntry,
                onCommit: save
            )
        }
        .presentationCornerRadius(26)
        .presentationBackground(.thinMaterial)
    }

    private func save(_ canonical: Double) {
        entry.quantity = canonical
        try? context.save()
        dismiss()
    }

    private func deleteEntry() {
        context.delete(entry)
        try? context.save()
        dismiss()
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            QuantityEditSheet(entry: DiaryEntry(
                loggedAt: Date(),
                dayKey: DayKey.today,
                productName: "Oatmeal",
                basis: .per100g,
                quantity: 60,
                per100Calories: 379,
                per100Protein: 13.2,
                per100Fat: 6.5,
                per100Carbs: 67.7,
                per100Micros: [:],
                productID: nil
            ))
        }
        .modelContainer(PreviewData.container)
}
