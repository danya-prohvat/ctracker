import SwiftUI

/// "Calculate for me" sheet: sex, age, height, weight, activity and goal
/// direction → GoalCalculator.plan, applied back into the goals editor.
/// A native grouped form styled like the other modal pickers (see
/// LanguagePickerSheet) so every sheet in the app reads the same.
struct GoalsCalculatorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onApply: (MacroPlan) -> Void

    @State private var sex: CalcSex = .unspecified
    @State private var age: Int = 25
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var activity: CalcActivity = .light
    @State private var direction: CalcGoalDirection = .maintain

    private let directions: [CalcGoalDirection] = [.lose, .maintain, .gain]

    private var height: Double? { Format.parse(heightText) }
    private var weight: Double? { Format.parse(weightText) }
    private var canApply: Bool { (height ?? 0) > 0 && (weight ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("About you") {
                    Picker("Sex", selection: $sex) {
                        ForEach(CalcSex.allCases, id: \.self) { value in
                            Text(sexLabel(value)).tag(value)
                        }
                    }
                    Picker("Age", selection: $age) {
                        ForEach(10...100, id: \.self) { years in
                            Text("\(years)").tag(years)
                        }
                    }
                    measurementField("Height", text: $heightText, unit: "cm")
                    measurementField("Weight", text: $weightText, unit: "kg")
                }

                Section("Activity") {
                    Picker("Activity", selection: $activity) {
                        ForEach(CalcActivity.allCases, id: \.self) { value in
                            Text(activityLabel(value)).tag(value)
                        }
                    }
                }

                Section("Goal") {
                    Picker("Goal", selection: $direction) {
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { apply() }
                        .disabled(!canApply)
                        .fontWeight(.semibold)
                }
            }
            .tint(Theme.accentLabel)
        }
        .presentationDragIndicator(.visible)
    }

    private func measurementField(
        _ title: LocalizedStringKey, text: Binding<String>, unit: String
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .numericInputLimit(text, maxDigits: 3)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
            Text(verbatim: unit)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 34, alignment: .leading)
        }
    }

    /// The calculator derives lose/maintain/gain from the current→target
    /// difference, so encode the chosen direction as a ±5 kg target offset.
    private func apply() {
        guard let heightCm = height, let weightKg = weight else { return }
        let targetWeightKg: Double
        switch direction {
        case .lose: targetWeightKg = weightKg - 5
        case .maintain: targetWeightKg = weightKg
        case .gain: targetWeightKg = weightKg + 5
        }
        let plan = GoalCalculator.plan(
            sex: sex,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            activity: activity,
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

#Preview {
    GoalsCalculatorSheet { _ in }
}
