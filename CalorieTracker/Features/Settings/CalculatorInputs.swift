import Foundation

/// The goals calculator's editable answers, loaded from and saved back to the
/// body profile in `UserSettings` (user decision 2026-09-28: the last answers
/// are remembered, and onboarding shares the same profile). Height and
/// weight stay text in the unit system the sheet shows; the parsed metric
/// values feed the math.
struct CalculatorInputs {
    var sex: CalcSex = .unspecified
    var age = 25
    var heightText = ""
    var feetText = ""
    var inchesText = ""
    var weightText = ""
    var activity: CalcActivity = .light
    var direction: CalcGoalDirection = .maintain

    let isImperial: Bool

    init(settings: UserSettings?, unitSystem: UnitSystem) {
        isImperial = unitSystem == .us
        guard let settings else { return }
        sex = settings.profileSex ?? .unspecified
        age = settings.profileAge ?? 25
        activity = settings.profileActivity ?? .light
        if let cm = settings.profileHeightCm {
            if isImperial {
                let inches = BodyUnits.inches(fromCm: cm).rounded()
                feetText = Format.editable((inches / BodyUnits.inchesPerFoot).rounded(.down))
                inchesText = Format.editable(inches.truncatingRemainder(dividingBy: BodyUnits.inchesPerFoot))
            } else {
                heightText = Format.editable(cm)
            }
        }
        if let kg = settings.profileWeightKg {
            weightText = Format.editable(isImperial ? BodyUnits.lbs(fromKg: kg) : kg)
            if let target = settings.profileTargetWeightKg {
                direction = GoalCalculator.direction(currentKg: kg, targetKg: target)
            }
        }
    }

    var heightCm: Double? {
        guard isImperial else { return Format.parse(heightText) }
        let inches = (Format.parse(feetText) ?? 0) * BodyUnits.inchesPerFoot
            + (Format.parse(inchesText) ?? 0)
        return inches > 0 ? BodyUnits.cm(fromInches: inches) : nil
    }

    var weightKg: Double? {
        guard let value = Format.parse(weightText) else { return nil }
        return isImperial ? BodyUnits.kg(fromLbs: value) : value
    }

    var canApply: Bool { (heightCm ?? 0) > 0 && (weightKg ?? 0) > 0 }

    /// The direction is encoded as a target weight (±5 kg, as before). A
    /// stored target survives while it still implies the chosen direction,
    /// so an onboarding "−6 kg" isn't flattened to "−5 kg" by a re-apply.
    func targetWeightKg(currentKg: Double, stored: Double?) -> Double {
        if let stored,
           GoalCalculator.direction(currentKg: currentKg, targetKg: stored) == direction {
            return stored
        }
        switch direction {
        case .lose: return currentKg - 5
        case .maintain: return currentKg
        case .gain: return currentKg + 5
        }
    }

    func save(to settings: UserSettings, heightCm: Double, weightKg: Double, targetWeightKg: Double) {
        settings.updateBodyProfile(sex: sex, age: age, heightCm: heightCm, weightKg: weightKg,
                                   activity: activity, targetWeightKg: targetWeightKg)
    }
}
