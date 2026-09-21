import Foundation

enum NutritionMath {
    /// kcal from macros: protein×4 + fat×9 + carbs×4 (spec §5).
    static func calories(protein: Double, fat: Double, carbs: Double) -> Double {
        protein * 4 + fat * 9 + carbs * 4
    }

    /// Scale a per-100 value to a canonical quantity (g / ml).
    static func scaled(per100 value: Double, quantity: Double) -> Double {
        value * quantity / 100.0
    }

    /// Net carbs = carbs − fiber, floored at 0 (spec §6).
    static func netCarbs(carbs: Double, fiber: Double) -> Double {
        max(0, carbs - fiber)
    }

    /// % of calories from each macro, for the Today breakdown (spec §6).
    /// Largest-remainder rounding: the three always sum to exactly 100
    /// (independent rounding gave 99/101 for ~23% of inputs). All zero when
    /// there are no macro calories.
    static func macroCaloriePercents(protein: Double, fat: Double, carbs: Double) -> (p: Int, f: Int, c: Int) {
        let kcal = [protein * 4, fat * 9, carbs * 4]
        let total = kcal.reduce(0, +)
        guard total > 0 else { return (0, 0, 0) }
        let exact = kcal.map { $0 / total * 100 }
        var result = exact.map { Int($0.rounded(.down)) }
        let byRemainder = exact.indices.sorted {
            exact[$0] - exact[$0].rounded(.down) > exact[$1] - exact[$1].rounded(.down)
        }
        for index in byRemainder.prefix(max(0, 100 - result.reduce(0, +))) {
            result[index] += 1
        }
        return (result[0], result[1], result[2])
    }
}
