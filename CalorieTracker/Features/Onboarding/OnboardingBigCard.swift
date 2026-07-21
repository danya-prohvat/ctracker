import SwiftUI

/// Big square option card (onboarding sex step).
struct OnboardingBigCard: View {
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
