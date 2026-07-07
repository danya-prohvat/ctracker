import SwiftUI

/// Onboarding answers → daily macro plan (spec §8). Pure math, no persistence.
/// Raw answers are consumed here and only the resulting plan is ever stored.

enum CalcSex: String, CaseIterable, Identifiable {
    case female
    case male
    case unspecified

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .female: return "Female"
        case .male: return "Male"
        case .unspecified: return "Prefer not to say"
        }
    }
}

enum CalcActivity: String, CaseIterable, Identifiable {
    case sedentary
    case light
    case moderate
    case intense

    var id: String { rawValue }

    /// TDEE multiplier applied over BMR.
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .intense: return 1.725
        }
    }

    /// Short card title.
    var label: LocalizedStringKey {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Lightly active"
        case .moderate: return "Active"
        case .intense: return "Very active"
        }
    }

    /// Plain-life description shown on the onboarding cards.
    var descriptionKey: LocalizedStringKey {
        switch self {
        case .sedentary: return "Desk job, little exercise"
        case .light: return "Light training 1–3× a week"
        case .moderate: return "Training 3–5× a week"
        case .intense: return "Daily intense training"
        }
    }
}

enum CalcGoalDirection {
    case lose
    case maintain
    case gain
}

struct MacroPlan {
    var calories: Double
    var protein: Double
    var fat: Double
    var carbs: Double
}

enum GoalCalculator {
    /// ±0.5 kg around the current weight counts as "maintain".
    static func direction(currentKg: Double, targetKg: Double) -> CalcGoalDirection {
        let diff = targetKg - currentKg
        if abs(diff) <= 0.5 { return .maintain }
        return diff < 0 ? .lose : .gain
    }

    /// Mifflin-St Jeor BMR → TDEE → calorie target by goal direction → macros.
    /// Macros are rounded to whole grams and calories is set to their exact sum
    /// (protein×4 + fat×9 + carbs×4) so the plan is internally consistent.
    static func plan(
        sex: CalcSex,
        age: Int,
        heightCm: Double,
        weightKg: Double,
        activity: CalcActivity,
        targetWeightKg: Double
    ) -> MacroPlan {
        // Mifflin-St Jeor (spec §8 step 1); unspecified = average of both sexes.
        let maleBMR = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
        let femaleBMR = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 161
        let bmr: Double
        switch sex {
        case .male: bmr = maleBMR
        case .female: bmr = femaleBMR
        case .unspecified: bmr = (maleBMR + femaleBMR) / 2
        }

        let tdee = bmr * activity.multiplier

        let target: Double
        switch direction(currentKg: weightKg, targetKg: targetWeightKg) {
        case .lose: target = tdee * 0.825      // −17.5% (middle of the −15…−20% band)
        case .maintain: target = tdee
        case .gain: target = tdee * 1.10       // +10%
        }

        // Macros: protein from current body weight, fat 25% of calories, carbs the rest.
        let protein = max(30, (1.8 * weightKg).rounded())
        let fat = max(20, (target * 0.25 / 9).rounded())
        let carbs = max(0, ((target - protein * 4 - fat * 9) / 4).rounded())

        return MacroPlan(
            calories: NutritionMath.calories(protein: protein, fat: fat, carbs: carbs),
            protein: protein,
            fat: fat,
            carbs: carbs
        )
    }
}
