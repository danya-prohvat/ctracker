import Foundation
import SwiftData

/// Debug-only sample data, seeded when the app is launched with `-seedSample 1`
/// and the store is empty. Used to visually verify the data → UI path.
enum Seeder {
    @MainActor
    static func seedIfRequested(_ context: ModelContext) {
        #if DEBUG
        guard UserDefaults.standard.bool(forKey: "seedSample") else { return }
        seedSampleData(context)
        #endif
    }

    #if DEBUG
    /// How many days of history to generate (back from today, inclusive).
    private static let historyDays = 30

    /// A sample product plus a typical logged portion (canonical g / ml).
    private struct SampleFood {
        let name: String
        let basis: Basis
        let calories, protein, fat, carbs: Double
        let micros: [String: Double]
        let portion: Double
        /// Non-nil marks the sample as "scanned" (exercises the scanned badge).
        var barcode: String? = nil
    }

    /// Richer catalog than a single meal — enough variety to fill a month and
    /// exercise macro + micro aggregation across the free/premium nutrient set.
    private static let sampleFoods: [SampleFood] = [
        .init(name: "Oatmeal", basis: .per100g, calories: 380, protein: 13, fat: 7, carbs: 67,
              micros: ["fiber": 10, "sugar": 1, "iron": 4.7, "magnesium": 177], portion: 60,
              barcode: "4820000000017"),
        .init(name: "Milk 2%", basis: .per100ml, calories: 50, protein: 3.4, fat: 2, carbs: 4.8,
              micros: ["sugar": 4.8, "calcium": 120, "saturatedFat": 1.3], portion: 250,
              barcode: "4820000000024"),
        .init(name: "Banana", basis: .per100g, calories: 89, protein: 1.1, fat: 0.3, carbs: 23,
              micros: ["fiber": 2.6, "sugar": 12, "potassium": 358, "vitaminB6": 0.4, "vitaminC": 8.7], portion: 120),
        .init(name: "Chicken breast", basis: .per100g, calories: 165, protein: 31, fat: 3.6, carbs: 0,
              micros: ["saturatedFat": 1, "sodium": 74, "potassium": 256], portion: 150,
              barcode: "4820000000048"),
        .init(name: "White rice", basis: .per100g, calories: 130, protein: 2.7, fat: 0.3, carbs: 28,
              micros: ["fiber": 0.4, "sodium": 1], portion: 180),
        .init(name: "Greek yogurt", basis: .per100g, calories: 59, protein: 10, fat: 0.4, carbs: 3.6,
              micros: ["sugar": 3.2, "calcium": 110, "saturatedFat": 0.1], portion: 170,
              barcode: "4820000000062"),
        .init(name: "Egg", basis: .per100g, calories: 155, protein: 13, fat: 11, carbs: 1.1,
              micros: ["saturatedFat": 3.3, "cholesterol": 373, "vitaminD": 2, "vitaminB12": 0.9, "choline": 294], portion: 100),
        .init(name: "Almonds", basis: .per100g, calories: 579, protein: 21, fat: 50, carbs: 22,
              micros: ["fiber": 12.5, "sugar": 4.4, "saturatedFat": 3.8, "vitaminE": 25.6, "magnesium": 270], portion: 30,
              barcode: "4820000000079"),
        .init(name: "Apple", basis: .per100g, calories: 52, protein: 0.3, fat: 0.2, carbs: 14,
              micros: ["fiber": 2.4, "sugar": 10, "vitaminC": 4.6, "potassium": 107], portion: 150),
        .init(name: "Salmon", basis: .per100g, calories: 208, protein: 20, fat: 13, carbs: 0,
              micros: ["saturatedFat": 3.1, "omega3": 2.3, "vitaminD": 11, "vitaminB12": 3.2, "sodium": 59], portion: 140),
        .init(name: "Whole wheat bread", basis: .per100g, calories: 247, protein: 13, fat: 3.4, carbs: 41,
              micros: ["fiber": 7, "sugar": 6, "sodium": 400, "iron": 2.5], portion: 60,
              barcode: "4820000000086"),
        .init(name: "Olive oil", basis: .per100ml, calories: 884, protein: 0, fat: 100, carbs: 0,
              micros: ["saturatedFat": 13.8], portion: 15),
        .init(name: "Broccoli", basis: .per100g, calories: 34, protein: 2.8, fat: 0.4, carbs: 7,
              micros: ["fiber": 2.6, "sugar": 1.7, "vitaminC": 89, "vitaminK": 102, "potassium": 316], portion: 120),
        .init(name: "Pasta", basis: .per100g, calories: 158, protein: 5.8, fat: 0.9, carbs: 31,
              micros: ["fiber": 1.8, "sodium": 6], portion: 200,
              barcode: "4820000000093"),
    ]

    /// Meal slots as (hour, minute, candidate indices into `sampleFoods`).
    /// Each day rotates through candidates so daily totals vary but stay plausible.
    private static let slots: [(hour: Int, minute: Int, options: [Int])] = [
        (8, 0, [0, 6, 10]),     // breakfast main
        (8, 20, [1, 5]),        // breakfast side
        (13, 0, [3, 9]),        // lunch protein
        (13, 10, [4, 13]),      // lunch carb
        (16, 0, [7, 8, 2]),     // snack
        (19, 30, [9, 3, 12]),   // dinner protein
        (19, 45, [12, 4, 11]),  // dinner side
    ]

    /// Each day's total as a fraction of the calorie goal, cycled by day so the
    /// calendar shows every ring state: under (<80% → neutral gray), on target
    /// (80–105% → green) and over (>105% → amber). Roughly balanced across the
    /// three so all colors are visible in any visible week/month.
    private static let dayRatios: [Double] = [
        0.95, 0.68, 1.18, 0.88, 0.72, 1.30, 1.02, 0.60, 1.10, 0.83,
    ]

    /// Seeds the sample set into an empty store (also reachable from the debug
    /// "Test" card in Settings). Returns the number of diary entries inserted,
    /// or 0 when the store already has products and nothing was seeded.
    @MainActor
    @discardableResult
    static func seedSampleData(_ context: ModelContext) -> Int {
        let existing = (try? context.fetchCount(FetchDescriptor<Product>())) ?? 0
        guard existing == 0 else { return 0 }

        let now = Date()
        let cal = Calendar.current
        // Daily totals are scaled toward this so ring states are deterministic.
        let goal = UserSettings.current(in: context).calorieGoal ?? 2000

        // One Product per sample food; recency staggered so "My products" sorts nicely.
        let products = sampleFoods.enumerated().map { index, food -> Product in
            let p = Product(name: food.name, basis: food.basis,
                            calories: food.calories, protein: food.protein,
                            fat: food.fat, carbs: food.carbs, micros: food.micros,
                            barcode: food.barcode,
                            lastQuantity: food.portion,
                            lastLoggedAt: now.addingTimeInterval(-Double(index) * 3600))
            context.insert(p)
            return p
        }

        var inserted = 0
        for dayOffset in 0..<historyDays {
            guard let dayStart = cal.date(byAdding: .day, value: -dayOffset,
                                          to: cal.startOfDay(for: now)) else { continue }
            // Scale the whole day's portions so its total lands on the target
            // fraction of the goal — this is what fixes each day's ring state.
            let ratio = dayRatios[dayOffset % dayRatios.count]
            let dayScale = ratio * goal / dayBaseCalories(dayOffset: dayOffset)
            for (slotIndex, slot) in slots.enumerated() {
                let foodIndex = slot.options[(dayOffset + slotIndex) % slot.options.count]
                let food = sampleFoods[foodIndex]
                let date = cal.date(bySettingHour: slot.hour, minute: slot.minute,
                                    second: 0, of: dayStart) ?? dayStart
                guard date <= now else { continue }   // skip future slots for today
                context.insert(entry(from: products[foodIndex],
                                     food: food, quantity: food.portion * dayScale, at: date))
                inserted += 1
            }
        }

        try? context.save()
        return inserted
    }

    /// Unscaled calories a full day of slots contributes at nominal portions.
    /// Used to derive the per-day scale that hits the target ring state.
    private static func dayBaseCalories(dayOffset: Int) -> Double {
        slots.enumerated().reduce(0) { total, pair in
            let (slotIndex, slot) = pair
            let food = sampleFoods[slot.options[(dayOffset + slotIndex) % slot.options.count]]
            return total + food.calories * food.portion / 100
        }
    }

    /// Builds an immutable per-100 snapshot entry from a product (spec §2.1).
    private static func entry(from p: Product, food: SampleFood,
                              quantity: Double, at date: Date) -> DiaryEntry {
        DiaryEntry(loggedAt: date, dayKey: DayKey.string(from: date),
                   productName: p.name, basis: p.basis, quantity: quantity,
                   per100Calories: p.calories, per100Protein: p.protein,
                   per100Fat: p.fat, per100Carbs: p.carbs,
                   per100Micros: p.micros, productID: p.id,
                   wasScanned: p.wasScanned)
    }
    #endif
}
