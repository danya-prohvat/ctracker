import SwiftUI

/// Shared layout scaffold for the onboarding question steps and the picker
/// bindings (metric is the stored truth; imperial converts at the binding
/// boundary). Split out of OnboardingFlow to keep files under the 200-line
/// budget.
extension OnboardingFlow {

    /// Question steps: the title + controls block floats vertically centered
    /// between the top bar and the footer (user decision 2026-07-21 — was
    /// pinned top); the footer (Continue) stays pinned at the bottom.
    func stepScaffold<Content: View, Footer: View>(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

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

                content()
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 24)

            footer()
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
        .contentColumn()
    }

    // MARK: - Picker bindings (metric stored internally, imperial converted)

    var heightCmSelection: Binding<Int> {
        Binding(
            get: { onboardingClamp(Int(heightCm.rounded()), 120, 220) },
            set: { heightCm = Double($0) }
        )
    }

    var heightInchesSelection: Binding<Int> {
        Binding(
            get: { onboardingClamp(Int(BodyUnits.inches(fromCm: heightCm).rounded()), 48, 84) },
            set: { heightCm = BodyUnits.cm(fromInches: Double($0)) }
        )
    }

    var weightKgSelection: Binding<Int> {
        Binding(
            get: { onboardingClamp(Int(weightKg.rounded()), 35, 200) },
            set: { weightKg = Double($0) }
        )
    }

    var weightLbsSelection: Binding<Int> {
        Binding(
            get: { onboardingClamp(Int(BodyUnits.lbs(fromKg: weightKg).rounded()), 77, 440) },
            set: { weightKg = BodyUnits.kg(fromLbs: Double($0)) }
        )
    }

    var targetKgSelection: Binding<Int> {
        Binding(
            get: { onboardingClamp(Int(targetWeightKg.rounded()), 35, 200) },
            set: { targetWeightKg = Double($0) }
        )
    }

    var targetLbsSelection: Binding<Int> {
        Binding(
            get: { onboardingClamp(Int(BodyUnits.lbs(fromKg: targetWeightKg).rounded()), 77, 440) },
            set: { targetWeightKg = BodyUnits.kg(fromLbs: Double($0)) }
        )
    }
}

fileprivate func onboardingClamp(_ value: Int, _ lo: Int, _ hi: Int) -> Int {
    min(max(value, lo), hi)
}
