import SwiftUI

/// Onboarding flow control that writes to the store: plan computation, the
/// remembered body profile, Skip and Continue. Split out of OnboardingFlow
/// to keep it under the file-size limit (the state is internal on purpose).
extension OnboardingFlow {
    func computePlan() {
        let plan = GoalCalculator.plan(
            sex: sex ?? .unspecified,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            activity: activity ?? .moderate,
            targetWeightKg: targetInitialized ? targetWeightKg : weightKg
        )
        planCalories = plan.calories
        planProtein = plan.protein
        planFat = plan.fat
        planCarbs = plan.carbs
    }

    /// Remembered answers (user decision 2026-09-28, overrides spec §8 "raw
    /// answers are never stored"): written on every advance so a resumed or
    /// re-run onboarding — and the goals calculator — start from them. The
    /// target is stored only once its step initialised it; otherwise that
    /// step could no longer default to the current weight.
    func saveProfile() {
        settings.updateBodyProfile(
            sex: sex, age: age, heightCm: heightCm, weightKg: weightKg,
            activity: activity,
            targetWeightKg: targetInitialized ? targetWeightKg : nil
        )
    }

    /// Skip: finish immediately, defaults stay untouched (spec §8).
    func skip() {
        settings.onboardingCompleted = true
        settings.onboardingStep = 0
        try? context.save()
        onFinish()
    }

    /// Continue on "Your plan": write the resulting plan and the final
    /// answers, then hand off to the host (soft paywall a beat later).
    func finish() {
        if planCalories <= 0 { computePlan() }
        settings.calorieGoal = planCalories
        settings.proteinGoal = planProtein
        settings.fatGoal = planFat
        settings.carbGoal = planCarbs
        saveProfile()
        settings.onboardingCompleted = true
        settings.onboardingStep = 0
        try? context.save()
        onFinish()
    }
}
