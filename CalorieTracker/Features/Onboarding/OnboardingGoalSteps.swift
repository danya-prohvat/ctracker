import SwiftUI

/// Onboarding steps 4–7 (spec §8): activity, target weight, the calculating
/// interlude and the editable "Your plan" result. Split out of OnboardingFlow
/// to keep files under the 200-line budget.
extension OnboardingFlow {

    // Step 4 — Activity.
    var activityStep: some View {
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
    var targetStep: some View {
        stepScaffold(title: "What's your target weight?") {
            VStack(spacing: 12) {
                Group {
                    if useImperial {
                        Picker("Target weight", selection: targetLbsSelection) {
                            ForEach(77...440, id: \.self) { value in
                                Text("\(value) lbs").tag(value)
                            }
                        }
                    } else {
                        Picker("Target weight", selection: targetKgSelection) {
                            ForEach(35...200, id: \.self) { value in
                                Text("\(value) kg").tag(value)
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
            ? String(localized: "\(Format.amount((diffKg * 2.20462).rounded())) lbs", bundle: AppLanguage.current)
            : String(localized: "\(Format.amount(diffKg)) kg", bundle: AppLanguage.current)

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
    var calculatingStep: some View {
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
    var resultStep: some View {
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
                .contentColumn()
            }
            .dismissesKeyboardOnTap()

            OnboardingPrimaryButton(title: "Continue") {
                // Blur any in-progress PlanEditor edit so it commits first.
                hideKeyboard()
                Task {
                    try? await Task.sleep(for: .seconds(0.1))
                    finish()
                }
            }
            .padding(20)
            // Cap before the background so the material bar spans the screen
            // while the button stays on the column.
            .contentColumn()
            .background(.ultraThinMaterial)
        }
    }
}
