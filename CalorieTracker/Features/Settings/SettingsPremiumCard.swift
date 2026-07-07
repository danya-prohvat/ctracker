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
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Premium active")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Manages via App Store")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .settingsRowPadding()

            SettingsRowDivider()

            Link(destination: AppLinks.manageSubscriptionsURL) {
                HStack {
                    Text("Manage subscription")
                        .font(.system(size: 16))
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

    private var upgradeCard: some View {
        Button(action: onUpgrade) {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Try Premium")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("All nutrients, scanner, iCloud sync & full history")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text("Upgrade")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accentDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.fabTop, Theme.fabBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
