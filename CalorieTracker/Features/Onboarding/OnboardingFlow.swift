import SwiftUI
import SwiftData
import UIKit

/// Full-screen onboarding (spec §8): one question per screen, thin progress bar
/// pinned top, small Skip in the corner on every step, auto-advance on card
/// steps. Raw answers (sex / age / height / weight / activity / target) live
/// only in @State and are never persisted — only the resulting plan is written
/// to UserSettings at the end. The current step index is persisted after each
/// advance so an interrupted onboarding resumes where it left off.
struct OnboardingFlow: View {
    @Environment(\.modelContext) private var context

    let settings: UserSettings
    let onFinish: () -> Void

    // Raw answers — @State only, never persisted (spec §8).
    @State private var sex: CalcSex?
    @State private var age = 25
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    @State private var activity: CalcActivity?
    @State private var targetWeightKg: Double = 70
    @State private var targetInitialized = false
    @State private var useImperial: Bool

    // Computed plan (PlanEditor bindings on the result step).
    @State private var planCalories: Double = 0
    @State private var planProtein: Double = 0
    @State private var planFat: Double = 0
    @State private var planCarbs: Double = 0

    @State private var step: Int
    @State private var isAdvancing = false
    @State private var calcPhase = 0
    @State private var showPaywall = false

    private static let stepCount = 8

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
        .background(Theme.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $showPaywall, onDismiss: finish) {
            PaywallView()
        }
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
        case 6: resultStep.transition(stepTransition)
        default: paywallStep.transition(stepTransition)
        }
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    // Step 1 — Sex.
    private var sexStep: some View {
        stepScaffold(
            title: "What's your sex?",
            subtitle: "Used only to estimate your calorie needs."
        ) {
            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    OnboardingBigCard(
                        icon: "figure.stand.dress",
                        title: CalcSex.female.label,
                        selected: sex == .female
                    ) {
                        choose { sex = .female }
                    }
                    OnboardingBigCard(
                        icon: "figure.stand",
                        title: CalcSex.male.label,
                        selected: sex == .male
                    ) {
                        choose { sex = .male }
                    }
                }
                Button {
                    choose { sex = .unspecified }
                } label: {
                    Text(CalcSex.unspecified.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(sex == .unspecified ? Theme.accent : Theme.textSecondary)
                        .padding(.vertical, 8)
                }
            }
        } footer: {
            EmptyView()
        }
    }

    // Step 2 — Age.
    private var ageStep: some View {
        stepScaffold(title: "How old are you?") {
            Picker("Age", selection: $age) {
                ForEach(10...99, id: \.self) { value in
                    Text(verbatim: "\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
            .clipped()
        } footer: {
            OnboardingPrimaryButton(title: "Continue") { advance() }
        }
    }

    // Step 3 — Height & weight (one screen, unit toggle on the screen).
    private var bodyStep: some View {
        stepScaffold(title: "Height & weight") {
            VStack(spacing: 20) {
                unitsToggle

                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("Height")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Group {
                            if useImperial {
                                Picker("Height", selection: heightInchesSelection) {
                                    ForEach(48...84, id: \.self) { value in
                                        Text(verbatim: "\(value / 12)′\(value % 12)″").tag(value)
                                    }
                                }
                            } else {
                                Picker("Height", selection: heightCmSelection) {
                                    ForEach(120...220, id: \.self) { value in
                                        Text(verbatim: "\(value) cm").tag(value)
                                    }
                                }
                            }
                        }
                        .pickerStyle(.wheel)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text("Weight")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Group {
                            if useImperial {
                                Picker("Weight", selection: weightLbsSelection) {
                                    ForEach(77...440, id: \.self) { value in
                                        Text(verbatim: "\(value) lbs").tag(value)
                                    }
                                }
                            } else {
                                Picker("Weight", selection: weightKgSelection) {
                                    ForEach(35...200, id: \.self) { value in
                                        Text(verbatim: "\(value) kg").tag(value)
                                    }
                                }
                            }
                        }
                        .pickerStyle(.wheel)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 200)
            }
        } footer: {
            OnboardingPrimaryButton(title: "Continue") { advance() }
        }
    }

    private var unitsToggle: some View {
        Picker("Units", selection: $useImperial) {
            Text("cm · kg").tag(false)
            Text("ft · lbs").tag(true)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 240)
    }

    // Step 4 — Activity.
    private var activityStep: some View {
        stepScaffold(title: "How active are you?") {
            VStack(spacing: 12) {
                ForEach(CalcActivity.allCases) { option in
                    OnboardingRowCard(
                        title: option.label,
                        subtitle: option.descriptionKey,
                        selected: activity == option
                    ) {
                        choose { activity = option }
                    }
                }
            }
        } footer: {
            EmptyView()
        }
    }

    // Step 5 — Target weight.
    private var targetStep: some View {
        stepScaffold(title: "What's your target weight?") {
            VStack(spacing: 12) {
                Group {
                    if useImperial {
                        Picker("Target weight", selection: targetLbsSelection) {
                            ForEach(77...440, id: \.self) { value in
                                Text(verbatim: "\(value) lbs").tag(value)
                            }
                        }
                    } else {
                        Picker("Target weight", selection: targetKgSelection) {
                            ForEach(35...200, id: \.self) { value in
                                Text(verbatim: "\(value) kg").tag(value)
                            }
                        }
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 200)
                .clipped()

                targetCaption
            }
        } footer: {
            OnboardingPrimaryButton(title: "Continue") { advance() }
        }
        .onAppear {
            if !targetInitialized {
                targetWeightKg = weightKg
                targetInitialized = true
            }
        }
    }

    private var targetCaption: some View {
        let direction = GoalCalculator.direction(currentKg: weightKg, targetKg: targetWeightKg)
        let diffKg = abs(targetWeightKg - weightKg)
        // Safe default pace of 0.5 kg per week (spec §8).
        let weeks = max(1, Int((diffKg / 0.5).rounded(.up)))
        let amount = useImperial
            ? "\(Format.amount((diffKg * 2.20462).rounded())) lbs"
            : "\(Format.amount(diffKg)) kg"

        return Group {
            switch direction {
            case .maintain:
                Text("Goal: maintain weight")
            case .lose:
                Text("Goal: lose \(amount) · about \(weeks) weeks")
            case .gain:
                Text("Goal: gain \(amount) · about \(weeks) weeks")
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(Theme.accent)
        .animation(.easeInOut(duration: 0.15), value: targetWeightKg)
    }

    // Step 6 — Calculating (1.8 s, cycling texts, then auto-advance).
    private var calculatingStep: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accent)
            Text(calcPhase == 0 ? "Analyzing your data…" : "Calculating your plan…")
                .font(.headline)
                .foregroundStyle(Theme.textSecondary)
                .animation(.easeInOut(duration: 0.25), value: calcPhase)
            Spacer()
        }
        .padding(.horizontal, 20)
        .task {
            computePlan()
            try? await Task.sleep(for: .seconds(0.9))
            guard !Task.isCancelled else { return }
            withAnimation { calcPhase = 1 }
            try? await Task.sleep(for: .seconds(0.9))
            guard !Task.isCancelled else { return }
            advance()
        }
    }

    // Step 7 — Result: editable plan.
    private var resultStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Your plan")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Tweak anything — you can change it later in Settings.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 28)

                    // PlanEditor draws its own glass cards now — no extra wrapper.
                    PlanEditor(
                        calories: $planCalories,
                        protein: $planProtein,
                        fat: $planFat,
                        carbs: $planCarbs
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            OnboardingPrimaryButton(title: "Continue") {
                // Blur any in-progress PlanEditor edit so it commits first.
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                )
                Task {
                    try? await Task.sleep(for: .seconds(0.1))
                    advance()
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
        }
    }

    // Step 8 — Paywall (soft; dismissing it finishes onboarding).
    private var paywallStep: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(Theme.accent)
            Spacer()
        }
        .onAppear { showPaywall = true }
    }

    // MARK: - Step scaffold

    private func stepScaffold<Content: View, Footer: View>(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text(title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 28)

                content()
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 12)

            footer()
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Picker bindings (metric stored internally, imperial converted)

    private var heightCmSelection: Binding<Int> {
        Binding(
            get: { onboardingClamp(Int(heightCm.rounded()), 120, 220) },
            set: { heightCm = Double($0) }
        )
    }

    private var heightInchesSelection: Binding<Int> {
        Binding(
            get: { onboardingClamp(Int((heightCm / 2.54).rounded()), 48, 84) },
            set: { heightCm = Double($0) * 2.54 }
        )
    }

    private var weightKgSelection: Binding<Int> {
        Binding(
            get: { onboardingClamp(Int(weightKg.rounded()), 35, 200) },
            set: { weightKg = Double($0) }
        )
    }

    private var weightLbsSelection: Binding<Int> {
        Binding(
            get: { onboardingClamp(Int((weightKg * 2.20462).rounded()), 77, 440) },
            set: { weightKg = Double($0) / 2.20462 }
        )
    }

    private var targetKgSelection: Binding<Int> {
        Binding(
            get: { onboardingClamp(Int(targetWeightKg.rounded()), 35, 200) },
            set: { targetWeightKg = Double($0) }
        )
    }

    private var targetLbsSelection: Binding<Int> {
        Binding(
            get: { onboardingClamp(Int((targetWeightKg * 2.20462).rounded()), 77, 440) },
            set: { targetWeightKg = Double($0) / 2.20462 }
        )
    }

    // MARK: - Flow control

    /// Card steps: show the selected state for a brief beat, then auto-advance.
    private func choose(_ assign: () -> Void) {
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

    private func advance() {
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

    private func computePlan() {
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

    /// Finish (after the paywall step): write ONLY the resulting plan.
    private func finish() {
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

// MARK: - Helpers

fileprivate func onboardingClamp(_ value: Int, _ lo: Int, _ hi: Int) -> Int {
    min(max(value, lo), hi)
}

/// Big square option card (sex step).
fileprivate struct OnboardingBigCard: View {
    let icon: String
    let title: LocalizedStringKey
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundStyle(selected ? Theme.accent : Theme.textSecondary)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(selected ? Theme.accentSoft : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(selected ? Theme.accent : Theme.separator, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Full-width option card with a title and description (activity step).
fileprivate struct OnboardingRowCard: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(selected ? Theme.accentSoft : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(selected ? Theme.accent : Theme.separator, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Big accent action button pinned near the bottom of a step.
fileprivate struct OnboardingPrimaryButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accent))
        }
    }
}

#Preview {
    let container = PreviewData.container
    return OnboardingFlow(settings: UserSettings.current(in: container.mainContext), onFinish: {})
        .modelContainer(container)
}
