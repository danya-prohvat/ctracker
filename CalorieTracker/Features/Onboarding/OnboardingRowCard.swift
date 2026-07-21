import SwiftUI

/// Full-width option card with a title and description (onboarding activity step).
struct OnboardingRowCard: View {
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
