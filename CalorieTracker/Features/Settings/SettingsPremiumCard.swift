import SwiftUI

/// Premium banner on the Settings root: upgrade CTA for free users,
/// subscription status + manage link for premium users. Gating semantics
/// stay behind `PremiumGate`; only the container is restyled.
struct SettingsPremiumCard: View {
    let settings: UserSettings
    let onUpgrade: () -> Void

    var body: some View {
        if PremiumGate.isPremium(settings: settings) {
            activeCard
        } else {
            upgradeCard
        }
    }

    // MARK: - Premium active

    private var activeCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Premium active")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Manages via App Store")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .settingsRowPadding()

            SettingsRowDivider()

            Link(destination: AppLinks.manageSubscriptionsURL) {
                HStack {
                    Text("Manage subscription")
                        .font(.callout)
                        .foregroundStyle(Theme.accentLabel)
                    Spacer(minLength: 12)
                    SettingsRowChevron()
                }
                .settingsRowPadding()
                .contentShape(Rectangle())
            }
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    // MARK: - Upgrade CTA

    /// Native upsell row (iCloud+ pattern): white card, Settings-style icon
    /// squircle, regular text colors and a soft tinted "Upgrade" capsule.
    private var upgradeCard: some View {
        Button(action: onUpgrade) {
            HStack(spacing: 12) {
                Image(systemName: "chart.pie.fill")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.fabTop, Theme.fabBottom],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Try Premium")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("All nutrients, scanner, iCloud sync & full history")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text("Upgrade")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accentDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.accentSoft))
            }
            .settingsRowPadding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassCard(cornerRadius: Theme.cornerRadius)
    }
}
