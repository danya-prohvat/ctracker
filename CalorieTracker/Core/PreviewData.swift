import Foundation
import SwiftData

/// In-memory container with sample data for SwiftUI previews.
enum PreviewData {
    @MainActor static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Product.self, DiaryEntry.self, UserSettings.self,
            configurations: config
        )
        let context = container.mainContext

        let settings = UserSettings()
        context.insert(settings)

        let oatmeal = Product(name: "Oatmeal", basis: .per100g,
                              calories: 380, protein: 13, fat: 7, carbs: 67,
                              micros: ["fiber": 10, "sugar": 1],
                              lastQuantity: 60, lastLoggedAt: Date())
        let milk = Product(name: "Milk 2%", basis: .per100ml,
                           calories: 50, protein: 3.4, fat: 2, carbs: 4.8,
                           micros: ["sugar": 4.8, "calcium": 120],
                           lastQuantity: 200, lastLoggedAt: Date().addingTimeInterval(-3600))
        let banana = Product(name: "Banana", basis: .per100g,
                             calories: 89, protein: 1.1, fat: 0.3, carbs: 23,
                             micros: ["fiber": 2.6, "sugar": 12, "potassium": 358],
                             lastQuantity: 120, lastLoggedAt: Date().addingTimeInterval(-7200))
        [oatmeal, milk, banana].forEach { context.insert($0) }

        let entry = DiaryEntry(
            dayKey: DayKey.today, productName: "Oatmeal", basis: .per100g,
            quantity: 60, per100Calories: 380, per100Protein: 13,
            per100Fat: 7, per100Carbs: 67, per100Micros: ["fiber": 10, "sugar": 1],
            productID: oatmeal.id
        )
        context.insert(entry)

        return container
    }()
}
