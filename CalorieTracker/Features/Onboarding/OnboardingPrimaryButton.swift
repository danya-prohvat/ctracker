import SwiftUI

/// Big accent action button pinned near the bottom of an onboarding step.
struct OnboardingPrimaryButton: View {
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
        .buttonStyle(.pressableCard)
    }
}
