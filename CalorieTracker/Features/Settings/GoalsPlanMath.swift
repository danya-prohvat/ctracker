import Foundation

/// Proportional macro rescaling used by `PlanEditor` when the calorie goal
/// changes (spec §5 "kcal ↔ macros").
enum GoalsPlanMath {
    private static let proteinFloor: Double = 30
    private static let fatFloor: Double = 20

    /// Proportionally rescale macros toward a calorie target, keeping the
    /// current percentage split. While scaling down, protein ≥ 30 g and
    /// fat ≥ 20 g: a macro pinned at its floor stays fixed and the others
    /// keep scaling. Results are rounded to whole grams.
    static func macros(
        forCalories target: Double,
        protein: Double,
        fat: Double,
        carbs: Double
    ) -> (protein: Double, fat: Double, carbs: Double) {
        let current = NutritionMath.calories(protein: protein, fat: fat, carbs: carbs)

        // Degenerate start (no macros yet): seed with a 20% P / 30% F / 50% C split.
        guard current > 0 else {
            return rounded(protein: target * 0.20 / 4, fat: target * 0.30 / 9, carbs: target * 0.50 / 4)
        }

        // Scaling up never violates the floors — plain proportional scale.
        if target >= current {
            let factor = target / current
            return rounded(protein: protein * factor, fat: fat * factor, carbs: carbs * factor)
        }

        // Scaling down with floors. At most two pins, so the loop settles in ≤ 3 passes.
        var pinProtein = false
        var pinFat = false
        for _ in 0..<3 {
            let pinnedCalories = (pinProtein ? proteinFloor * 4 : 0) + (pinFat ? fatFloor * 9 : 0)
            let freeCalories = (pinProtein ? 0 : protein * 4) + (pinFat ? 0 : fat * 9) + carbs * 4
            let factor = freeCalories > 0 ? max(0, (target - pinnedCalories) / freeCalories) : 0

            let p = pinProtein ? proteinFloor : protein * factor
            let f = pinFat ? fatFloor : fat * factor
            let c = carbs * factor

            if !pinProtein, p < proteinFloor {
                pinProtein = true
                continue
            }
            if !pinFat, f < fatFloor {
                pinFat = true
                continue
            }
            return rounded(protein: p, fat: f, carbs: c)
        }

        // Both pinned: carbs absorb whatever calories remain (floored at 0).
        return rounded(
            protein: proteinFloor,
            fat: fatFloor,
            carbs: max(0, (target - proteinFloor * 4 - fatFloor * 9) / 4)
        )
    }

    private static func rounded(
        protein: Double,
        fat: Double,
        carbs: Double
    ) -> (protein: Double, fat: Double, carbs: Double) {
        (protein.rounded(), fat.rounded(), carbs.rounded())
    }
}
