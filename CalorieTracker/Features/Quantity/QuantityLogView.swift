import SwiftUI
import SwiftData

/// Log flow entry: choose quantity for a food and write an immutable diary snapshot.
/// Pushed inside the Add-food navigation stack; draws the prototype header itself.
/// For a saved product a trailing pencil pushes the edit form (user request
/// 2026-09-27: the swipe/long-press edit in the list was undiscoverable); the
/// live values re-read from the product, so edits show up right after saving.
struct QuantityLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let food: LoggableFood
    /// The saved product behind `food`, when any — enables the edit pencil.
    var product: Product? = nil
    let dayKey: String
    let unitSystem: UnitSystem
    let onLogged: () -> Void
    /// "Today" as state, refreshed via `onPossibleDayChange` — the CTA copy
    /// must stay honest if the sheet sits open across midnight.
    @State private var todayKey = DayKey.today
    @State private var isEditing = false

    /// Reading the product's fields here keeps the header and live card in
    /// sync after the pushed edit form saves (the model is observable).
    private var current: LoggableFood { product?.loggable ?? food }

    var body: some View {
        QuantityEditor(
            name: current.name,
            wasScanned: current.wasScanned,
            basis: current.basis,
            per100Calories: current.per100Calories,
            per100Protein: current.per100Protein,
            per100Fat: current.per100Fat,
            per100Carbs: current.per100Carbs,
            unitSystem: unitSystem,
            // Start from the portion the product was entered for ("Per 30 g",
            // user decision 2026-09-27), 100 g / ml when none. Still never
            // the last logged quantity (user decision 2026-07-14 stands).
            initialCanonical: product?.servingAmount ?? 100,
            title: "Add quantity",
            // Day-aware CTA: logging into a past day from the calendar must
            // not promise "today" (fix 2026-09-07).
            ctaTitle: dayKey == todayKey ? "Add to today" : "Add",
            onBack: { dismiss() },      // pop back to the add list
            onCommit: log
        )
        .background(AppBackground())
        .toolbar {
            if product != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isEditing = true } label: {
                        Image(systemName: "pencil")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.accentLabel)
                    }
                    .accessibilityLabel("Edit product")
                }
            }
        }
        .navigationDestination(isPresented: $isEditing) {
            if let product {
                // Editing mode dismisses itself on save / back = pops here.
                NewProductForm(mode: .editing(product))
            }
        }
        .onPossibleDayChange { todayKey = DayKey.today }
    }

    private func log(_ canonical: Double) {
        DiaryLogger.log(current, quantity: canonical, dayKey: dayKey, in: context)
        onLogged()
    }
}

#Preview {
    NavigationStack {
        QuantityLogView(
            food: LoggableFood(
                productID: nil, name: "Greek yogurt", basis: .per100g,
                per100Calories: 59, per100Protein: 10, per100Fat: 0.4,
                per100Carbs: 3.6, per100Micros: [:], lastQuantity: 150
            ),
            dayKey: DayKey.today,
            unitSystem: .metric,
            onLogged: {}
        )
    }
    .modelContainer(PreviewData.container)
}
