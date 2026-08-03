import SwiftUI

/// Onboarding steps 1–3 (spec §8): sex, age, height & weight. Split out of
/// OnboardingFlow to keep files under the 200-line budget; state and flow
/// control live on the struct itself.
extension OnboardingFlow {

    // Step 1 — Sex.
    var sexStep: some View {
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
    var ageStep: some View {
        stepScaffold(title: "How old are you?") {
            Picker("Age", selection: $age) {
                ForEach(10...99, id: \.self) { value in
                    Text("\(value)").tag(value)
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
    var bodyStep: some View {
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
                                        Text("\(value) cm").tag(value)
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
                                        Text("\(value) lbs").tag(value)
                                    }
                                }
                            } else {
                                Picker("Weight", selection: weightKgSelection) {
                                    ForEach(35...200, id: \.self) { value in
                                        Text("\(value) kg").tag(value)
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
        .onChange(of: useImperial) { _, imperial in
            // Persist app-wide right away — before 2026-07-21 this was
            // @State-only, so the onboarding choice silently never stuck.
            settings.unitSystem = imperial ? .us : .metric
            try? context.save()
        }
    }
}
