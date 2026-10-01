import SwiftUI
import SwiftData
import UIKit

/// Full-screen onboarding (spec §8): one question per screen (block centered
/// vertically), thin progress bar pinned top, small Skip in the corner on
/// every step, auto-advance on card steps. Raw answers (sex / age / height /
/// weight / activity / target) are @State seeded from the body profile in
/// UserSettings and written back on every advance (user decision 2026-09-28,
/// overrides spec §8) — so an interrupted onboarding resumes with its
/// answers and the goals calculator starts from them. The resulting plan is
/// written to the daily goals at the end.
/// The closing soft paywall is NOT a step here — after the flow (finished or
/// skipped alike) the host (RootView) dismisses this cover, shows Today for a
/// beat and only then presents the paywall over it (user decision 2026-07-21),
/// so the paywall never reveals a still-dismissing onboarding behind it.
///
/// This file holds the state and step navigation; the step views live in
/// OnboardingAboutYouSteps / OnboardingGoalSteps, the shared scaffold and
/// picker bindings in OnboardingStepScaffold, plan / profile / finish in
/// OnboardingCompletion.
struct OnboardingFlow: View {
    // Internal (not private): the step-view extensions in sibling files use
    // the state, settings and context directly.
    @Environment(\.modelContext) var context

    let settings: UserSettings
    /// Fired on every answered question (host stops auto-dismissing then).
    var onStarted: () -> Void = {}
    let onFinish: () -> Void

    // Raw answers — seeded from the remembered body profile in init.
    @State var sex: CalcSex?
    @State var age: Int
    @State var heightCm: Double
    @State var weightKg: Double
    @State var activity: CalcActivity?
    @State var targetWeightKg: Double
    @State var targetInitialized: Bool
    @State var useImperial: Bool

    // Computed plan (PlanEditor bindings on the result step).
    @State var planCalories: Double = 0
    @State var planProtein: Double = 0
    @State var planFat: Double = 0
    @State var planCarbs: Double = 0

    @State private var step: Int
    @State private var isAdvancing = false
    @State private var goingBack = false
    @State var calcPhase = 0

    static let stepCount = 7

    init(settings: UserSettings, onStarted: @escaping () -> Void = {}, onFinish: @escaping () -> Void) {
        self.settings = settings
        self.onStarted = onStarted
        self.onFinish = onFinish
        _step = State(initialValue: min(max(settings.onboardingStep, 0), Self.stepCount - 1))
        _useImperial = State(initialValue: settings.unitSystem == .us)
        // Remembered answers: a resumed or re-run onboarding starts from what
        // was answered before; a stored target means its step already ran.
        _sex = State(initialValue: settings.profileSex)
        _age = State(initialValue: settings.profileAge ?? 25)
        _heightCm = State(initialValue: settings.profileHeightCm ?? 170)
        let weight = settings.profileWeightKg ?? 70
        _weightKg = State(initialValue: weight)
        _activity = State(initialValue: settings.profileActivity)
        _targetWeightKg = State(initialValue: settings.profileTargetWeightKg ?? weight)
        _targetInitialized = State(initialValue: settings.profileTargetWeightKg != nil)
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

    // MARK: - Top bar (Back + progress + Skip)

    /// Back is offered on every step but the first and the timed
    /// calculating interlude (which advances on its own).
    private var canGoBack: Bool { step > 0 && step != 5 }

    private var topBar: some View {
        OnboardingTopBar(
            progress: Double(step + 1) / Double(Self.stepCount),
            canGoBack: canGoBack, onBack: back, onSkip: skip
        )
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
            insertion: .move(edge: goingBack ? .leading : .trailing).combined(with: .opacity),
            removal: .move(edge: goingBack ? .trailing : .leading).combined(with: .opacity)
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
        goingBack = false
        onStarted()
        withAnimation(.easeInOut(duration: 0.3)) {
            step += 1
        }
        // Persist the resume point (spec §8) and the answers so far.
        settings.onboardingStep = step
        saveProfile()
        try? context.save()
    }

    /// Back one question; from "Your plan" it lands on the target step,
    /// skipping the calculating interlude (Continue there re-runs it).
    func back() {
        guard canGoBack, !isAdvancing else { return }
        goingBack = true
        calcPhase = 0
        withAnimation(.easeInOut(duration: 0.3)) {
            step = step == 6 ? 4 : step - 1
        }
        settings.onboardingStep = step
        saveProfile()
        try? context.save()
    }

    /// Resuming mid-flow after a relaunch: answers come back from the
    /// profile; late steps only need the plan recomputed.
    private func resumeIfNeeded() {
        if !targetInitialized, step >= 4 {
            targetWeightKg = weightKg
            targetInitialized = true
        }
        if step >= 5, planCalories <= 0 {
            computePlan()
        }
    }
}

#Preview {
    let container = PreviewData.container
    return OnboardingFlow(settings: UserSettings.current(in: container.mainContext), onFinish: {})
        .modelContainer(container)
}
