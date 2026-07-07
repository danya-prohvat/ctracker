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
    static func macroCaloriePercents(protein: Double, fat: Double, carbs: Double) -> (p: Int, f: Int, c: Int) {
        let pc = protein * 4, fc = fat * 9, cc = carbs * 4
        let total = pc + fc + cc
        guard total > 0 else { return (0, 0, 0) }
        return (Int((pc / total * 100).rounded()),
                Int((fc / total * 100).rounded()),
                Int((cc / total * 100).rounded()))
    }
}
