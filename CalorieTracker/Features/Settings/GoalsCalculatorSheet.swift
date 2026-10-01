import SwiftUI
import SwiftData

/// "Calculate for me" sheet: sex, age, height, weight, activity and goal
/// direction → GoalCalculator.plan, applied back into the goals editor.
/// A native grouped form styled like the other modal pickers (see
/// LanguagePickerSheet) so every sheet in the app reads the same.
/// Answers are remembered (user decision 2026-09-28): the sheet opens with
/// the body profile last saved by onboarding or a previous Apply, and Apply
/// writes it back (`CalculatorInputs`); closing without Apply changes nothing.
struct GoalsCalculatorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Drives the input units (cm·kg vs ft·lbs) the same way onboarding does;
    /// conversion happens once on Apply (`BodyUnits`), math stays metric.
    let unitSystem: UnitSystem
    let settings: UserSettings?
    let onApply: (MacroPlan) -> Void

    @State private var inputs: CalculatorInputs

    private let directions: [CalcGoalDirection] = [.lose, .maintain, .gain]

    init(settings: UserSettings?, unitSystem: UnitSystem, onApply: @escaping (MacroPlan) -> Void) {
        self.settings = settings
        self.unitSystem = unitSystem
        self.onApply = onApply
        _inputs = State(initialValue: CalculatorInputs(settings: settings, unitSystem: unitSystem))
    }

    private var isImperial: Bool { inputs.isImperial }

    var body: some View {
        NavigationStack {
            Form {
                Section("About you") {
                    Picker("Sex", selection: $inputs.sex) {
                        ForEach(CalcSex.allCases, id: \.self) { value in
                            Text(sexLabel(value)).tag(value)
                        }
                    }
                    Picker("Age", selection: $inputs.age) {
                        ForEach(10...100, id: \.self) { years in
                            Text("\(years)").tag(years)
                        }
                    }
                    if isImperial {
                        imperialHeightRow
                        measurementField("Weight", text: $inputs.weightText, unit: "lbs")
                    } else {
                        measurementField("Height", text: $inputs.heightText, unit: "cm")
                        measurementField("Weight", text: $inputs.weightText, unit: "kg")
                    }
                }

                Section("Activity") {
                    // Inline rows, not a menu (fix 2026-09-28): the menu
                    // style squeezed the chosen option next to the row label
                    // and truncated the long descriptions mid-word.
                    Picker("Activity", selection: $inputs.activity) {
                        ForEach(CalcActivity.allCases, id: \.self) { value in
                            Text(activityLabel(value)).tag(value)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Goal") {
                    Picker("Goal", selection: $inputs.direction) {
                        ForEach(directions, id: \.self) { value in
                            Text(directionLabel(value)).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .dismissesKeyboardOnTap()
            .navigationTitle("Calculate goals")
            .navigationBarTitleDisplayMode(.inline)
            // No Cancel button (user decision 2026-09-27): swipe-down closes.
            // Apply lives in a bottom CTA bar, not the nav bar.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ProductFormCTABar(title: "Apply", enabled: inputs.canApply) { apply() }
            }
            .tint(Theme.accentLabel)
        }
        .presentationDragIndicator(.visible)
    }

    private func measurementField(
        _ title: LocalizedStringKey, text: Binding<String>, unit: LocalizedStringKey
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .numericInputLimit(text, maxDigits: 3)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
            Text(unit)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .fixedSize()
                .frame(minWidth: 34, alignment: .leading)
        }
    }

    /// US height entry as feet + inches; the ′/″ marks are the same verbatim
    /// symbols the onboarding height wheel shows.
    /// Fields hug their digits (`fixedSize`) so the value reads as one
    /// "6′ 10″" group — fixed-width frames left a wide hole after the ′.
    private var imperialHeightRow: some View {
        HStack(spacing: 2) {
            Text("Height")
            Spacer()
            TextField("0", text: $inputs.feetText)
                .keyboardType(.decimalPad)
                .numericInputLimit($inputs.feetText, maxDigits: 1)
                .multilineTextAlignment(.trailing)
                .fixedSize()
            Text(verbatim: "′")
                .foregroundStyle(Theme.textSecondary)
            TextField("0", text: $inputs.inchesText)
                .keyboardType(.decimalPad)
                .numericInputLimit($inputs.inchesText, maxDigits: 2)
                .multilineTextAlignment(.trailing)
                .fixedSize()
                .padding(.leading, 8)
            Text(verbatim: "″")
                .foregroundStyle(Theme.textSecondary)
        }
    }

    /// The calculator derives lose/maintain/gain from the current→target
    /// difference, so the direction is encoded as a target weight (see
    /// `CalculatorInputs.targetWeightKg`). Apply also remembers the answers.
    private func apply() {
        guard let heightCm = inputs.heightCm, let weightKg = inputs.weightKg else { return }
        let targetWeightKg = inputs.targetWeightKg(
            currentKg: weightKg, stored: settings?.profileTargetWeightKg
        )
        if let settings {
            inputs.save(to: settings, heightCm: heightCm, weightKg: weightKg,
                        targetWeightKg: targetWeightKg)
            try? context.save()
        }
        let plan = GoalCalculator.plan(
            sex: inputs.sex,
            age: inputs.age,
            heightCm: heightCm,
            weightKg: weightKg,
            activity: inputs.activity,
            targetWeightKg: targetWeightKg
        )
        onApply(plan)
        dismiss()
    }

    private func sexLabel(_ value: CalcSex) -> LocalizedStringKey {
        switch value {
        case .female: return "Female"
        case .male: return "Male"
        case .unspecified: return "Prefer not to say"
        }
    }

    private func activityLabel(_ value: CalcActivity) -> LocalizedStringKey {
        switch value {
        case .sedentary: return "Desk job, little exercise"
        case .light: return "Light training 1–3× a week"
        case .moderate: return "Training 3–5× a week"
        case .intense: return "Daily intense training"
        }
    }

    private func directionLabel(_ value: CalcGoalDirection) -> LocalizedStringKey {
        switch value {
        case .lose: return "Lose"
        case .maintain: return "Maintain"
        case .gain: return "Gain"
        }
    }
}

#Preview("Metric") {
    GoalsCalculatorSheet(settings: nil, unitSystem: .metric) { _ in }
}

#Preview("US") {
    GoalsCalculatorSheet(settings: nil, unitSystem: .us) { _ in }
}
