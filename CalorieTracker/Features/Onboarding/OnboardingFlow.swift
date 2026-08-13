import SwiftUI
import SwiftData
import UIKit

/// Full-screen onboarding (spec §8): one question per screen (block centered
/// vertically), thin progress bar pinned top, small Skip in the corner on
/// every step, auto-advance on card steps. Raw answers (sex / age / height /
/// weight / activity / target) live
/// only in @State and are never persisted — only the resulting plan is written
/// to UserSettings at the end. The current step index is persisted after each
/// advance so an interrupted onboarding resumes where it left off.
/// The closing soft paywall is NOT a step here — after the flow (finished or
/// skipped alike) the host (RootView) dismisses this cover, shows Today for a
/// beat and only then presents the paywall over it (user decision 2026-07-21),
/// so the paywall never reveals a still-dismissing onboarding behind it.
///
/// This file holds the state and flow control; the step views live in
/// OnboardingAboutYouSteps / OnboardingGoalSteps, the shared scaffold and
/// picker bindings in OnboardingStepScaffold.
struct OnboardingFlow: View {
    // Internal (not private): the step-view extensions in sibling files use
    // the state, settings and context directly.
    @Environment(\.modelContext) var context

    let settings: UserSettings
    let onFinish: () -> Void

    // Raw answers — @State only, never persisted (spec §8).
    @State var sex: CalcSex?
    @State var age = 25
    @State var heightCm: Double = 170
    @State var weightKg: Double = 70
    @State var activity: CalcActivity?
    @State var targetWeightKg: Double = 70
    @State var targetInitialized = false
    @State var useImperial: Bool

    // Computed plan (PlanEditor bindings on the result step).
    @State var planCalories: Double = 0
    @State var planProtein: Double = 0
    @State var planFat: Double = 0
    @State var planCarbs: Double = 0

    @State private var step: Int
    @State private var isAdvancing = false
    @State var calcPhase = 0

    static let stepCount = 7

    init(settings: UserSettings, onFinish: @escaping () -> Void) {
        self.settings = settings
        self.onFinish = onFinish
        _step = State(initialValue: min(max(settings.onboardingStep, 0), Self.stepCount - 1))
        _useImperial = State(initialValue: settings.unitSystem == .us)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ZStack {
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppBackground())
        .onAppear(perform: resumeIfNeeded)
    }

    // MARK: - Top bar (progress + Skip, on every step)

    private var topBar: some View {
        HStack(spacing: 16) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.separator)
                    Capsule()
                        .fill(Theme.accent)
                        .frame(width: max(8, geo.size.width * Double(step + 1) / Double(Self.stepCount)))
                        .animation(.easeInOut(duration: 0.3), value: step)
                }
            }
            .frame(height: 4)

            Button("Skip") { skip() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .contentColumn()
    }

    // MARK: - Steps

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0: sexStep.transition(stepTransition)
        case 1: ageStep.transition(stepTransition)
        case 2: bodyStep.transition(stepTransition)
        case 3: activityStep.transition(stepTransition)
        case 4: targetStep.transition(stepTransition)
        case 5: calculatingStep.transition(stepTransition)
        default: resultStep.transition(stepTransition)
        }
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    // MARK: - Flow control

    /// Card steps: show the selected state for a brief beat, then auto-advance.
    func choose(_ assign: () -> Void) {
        guard !isAdvancing else { return }
        withAnimation(.easeOut(duration: 0.15)) {
            assign()
        }
        isAdvancing = true
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            isAdvancing = false
            guard !Task.isCancelled else { return }
            advance()
        }
    }

    func advance() {
        guard step < Self.stepCount - 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            step += 1
        }
        // Persist the resume point (spec §8) — never the raw answers.
        settings.onboardingStep = step
        try? context.save()
    }

    /// Resuming mid-flow after a relaunch: raw answers are gone by design, so
    /// late steps fall back to computing the plan from the current defaults.
    private func resumeIfNeeded() {
        if !targetInitialized, step >= 4 {
            targetWeightKg = weightKg
            targetInitialized = true
        }
        if step >= 5, planCalories <= 0 {
            computePlan()
        }
    }

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

    /// Skip: finish immediately, defaults stay untouched (spec §8).
    private func skip() {
        settings.onboardingCompleted = true
        settings.onboardingStep = 0
        try? context.save()
        onFinish()
    }

    /// Continue on "Your plan": write ONLY the resulting plan, then hand off
    /// to the host (which shows the soft paywall a beat later).
    func finish() {
        if planCalories <= 0 { computePlan() }
        settings.calorieGoal = planCalories
        settings.proteinGoal = planProtein
        settings.fatGoal = planFat
        settings.carbGoal = planCarbs
        settings.onboardingCompleted = true
        settings.onboardingStep = 0
        try? context.save()
        onFinish()
    }
}

#Preview {
    let container = PreviewData.container
    return OnboardingFlow(settings: UserSettings.current(in: container.mainContext), onFinish: {})
        .modelContainer(container)
}
