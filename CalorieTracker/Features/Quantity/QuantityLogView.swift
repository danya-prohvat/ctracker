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
            initialCanonical: food.lastQuantity ?? 100,
            title: "Add quantity",
            ctaTitle: "Add to today",
            onBack: { dismiss() },      // pop back to the add list
            onCommit: log
        )
        .background(AppBackground())
    }

    private func log(_ canonical: Double) {
        let now = Date()
        let entry = DiaryEntry(
            loggedAt: now,
            dayKey: dayKey,
            productName: food.name,
            basis: food.basis,
            quantity: canonical,
            per100Calories: food.per100Calories,
            per100Protein: food.per100Protein,
            per100Fat: food.per100Fat,
            per100Carbs: food.per100Carbs,
            per100Micros: food.per100Micros,
            productID: food.productID,
            wasScanned: food.wasScanned
        )
        context.insert(entry)

        // Update source product recency/prefill (only if saved).
        if let id = food.productID {
            var descriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let product = try? context.fetch(descriptor).first {
                product.lastQuantity = canonical
                product.lastLoggedAt = now
            }
        }
        try? context.save()
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
