import SwiftUI
import SwiftData

/// Log flow entry: choose quantity for a food and write an immutable diary snapshot.
/// Pushed inside the Add-food navigation stack; draws the prototype header itself.
struct QuantityLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let food: LoggableFood
    let dayKey: String
    let unitSystem: UnitSystem
    let onLogged: () -> Void
    /// "Today" as state, refreshed via `onPossibleDayChange` — the CTA copy
    /// must stay honest if the sheet sits open across midnight.
    @State private var todayKey = DayKey.today

    var body: some View {
        QuantityEditor(
            name: food.name,
            wasScanned: food.wasScanned,
            basis: food.basis,
            per100Calories: food.per100Calories,
            per100Protein: food.per100Protein,
            per100Fat: food.per100Fat,
            per100Carbs: food.per100Carbs,
            unitSystem: unitSystem,
            // Always start from the canonical default of 100 g / ml (user
            // decision 2026-07-14) — not from the last logged quantity.
            initialCanonical: 100,
            title: "Add quantity",
            // Day-aware CTA: logging into a past day from the calendar must
            // not promise "today" (fix 2026-09-07).
            ctaTitle: dayKey == todayKey ? "Add to today" : "Add",
            onBack: { dismiss() },      // pop back to the add list
            onCommit: log
        )
        .background(AppBackground())
        .onPossibleDayChange { todayKey = DayKey.today }
    }

    private func log(_ canonical: Double) {
        DiaryLogger.log(food, quantity: canonical, dayKey: dayKey, in: context)
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
