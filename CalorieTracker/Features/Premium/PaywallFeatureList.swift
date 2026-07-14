import SwiftUI

/// Value-proposition card on the paywall (spec §9).
struct PaywallFeatureList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PaywallFeatureRow(icon: "pills.fill",
                              title: "All 37 vitamins & minerals",
                              subtitle: "The complete micronutrient picture, every day.")
            PaywallFeatureRow(icon: "barcode.viewfinder",
                              title: "Unlimited barcode scanner",
                              subtitle: "Scan any product, no limits.")
            PaywallFeatureRow(icon: "icloud.fill",
                              title: "iCloud sync",
                              subtitle: "Your diary on all your devices.")
            PaywallFeatureRow(icon: "calendar",
                              title: "Full calendar history",
                              subtitle: "Look back further than 30 days.")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.card)
                .shadow(color: Theme.cardShadow, radius: 8, y: 2)
        )
    }
}

private struct PaywallFeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.accentSoft))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }
}
