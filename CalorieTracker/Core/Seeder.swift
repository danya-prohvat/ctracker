import Foundation
import SwiftData

/// Debug-only sample data, seeded when the app is launched with `-seedSample 1`
/// and the store is empty. Used to visually verify the data → UI path.
enum Seeder {
    @MainActor
    static func seedIfRequested(_ context: ModelContext) {
        #if DEBUG
        guard UserDefaults.standard.bool(forKey: "seedSample") else { return }
        let existing = (try? context.fetchCount(FetchDescriptor<Product>())) ?? 0
        guard existing == 0 else { return }

        let oatmeal = Product(name: "Oatmeal", basis: .per100g,
                              calories: 380, protein: 13, fat: 7, carbs: 67,
                              micros: ["fiber": 10, "sugar": 1],
                              lastQuantity: 60, lastLoggedAt: Date())
        let milk = Product(name: "Milk 2%", basis: .per100ml,
                           calories: 50, protein: 3.4, fat: 2, carbs: 4.8,
                           micros: ["sugar": 4.8, "calcium": 120],
                           lastQuantity: 250, lastLoggedAt: Date().addingTimeInterval(-3600))
        let banana = Product(name: "Banana", basis: .per100g,
                             calories: 89, protein: 1.1, fat: 0.3, carbs: 23,
                             micros: ["fiber": 2.6, "sugar": 12, "potassium": 358],
                             lastQuantity: 120, lastLoggedAt: Date().addingTimeInterval(-7200))
        let chicken = Product(name: "Chicken breast", basis: .per100g,
                              calories: 165, protein: 31, fat: 3.6, carbs: 0,
                              lastQuantity: 150, lastLoggedAt: Date().addingTimeInterval(-10800))
        [oatmeal, milk, banana, chicken].forEach { context.insert($0) }

        // Two logged entries today (immutable per-100 snapshots).
        let entries = [
            DiaryEntry(loggedAt: Date().addingTimeInterval(-9000), dayKey: DayKey.today,
                       productName: "Oatmeal", basis: .per100g, quantity: 60,
                       per100Calories: 380, per100Protein: 13, per100Fat: 7, per100Carbs: 67,
                       per100Micros: ["fiber": 10, "sugar": 1], productID: oatmeal.id),
            DiaryEntry(loggedAt: Date().addingTimeInterval(-3000), dayKey: DayKey.today,
                       productName: "Milk 2%", basis: .per100ml, quantity: 250,
                       per100Calories: 50, per100Protein: 3.4, per100Fat: 2, per100Carbs: 4.8,
                       per100Micros: ["sugar": 4.8, "calcium": 120], productID: milk.id),
        ]
        entries.forEach { context.insert($0) }
        try? context.save()
        #endif
    }
}
