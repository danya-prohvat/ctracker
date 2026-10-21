import SwiftUI
import StoreKit

/// Premium banner on the Settings root: upgrade CTA for free users,
/// subscription status + manage link for premium users. Gating semantics
/// stay behind `PremiumGate`; only the container is restyled.
///
/// The "Manage subscription" row shows for every premium user except a
/// Lifetime owner with no running subscription (user decision 2026-10-19,
/// replaces "always visible" from 2026-10-15): for them the system sheet is
/// empty. The verdict comes from the device's StoreKit cache
/// (`StoreEntitlementProbe.ownsLifetimeOnly`), never prompts, and defaults to
/// showing the row whenever the cache cannot say.
struct SettingsPremiumCard: View {
    let settings: UserSettings
    let onUpgrade: () -> Void

    @State private var showingManageSubscriptions = false
    @State private var hidesManageRow = false
    /// Yearly trial length from the warm quotes cache; nil = no eligible trial.
    @State private var trialDays: Int?

    @Environment(\.locale) private var locale

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
                    Text("All features unlocked")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .settingsRowPadding()

            if !hidesManageRow {
                SettingsRowDivider()
                manageSubscriptionRow
            }
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
        .task { hidesManageRow = await StoreEntitlementProbe.ownsLifetimeOnly() }
    }

    /// System sheet over the app (StoreKit), not a link out to the
    /// App Store — user decision 2026-09-29.
    private var manageSubscriptionRow: some View {
        Button {
            showingManageSubscriptions = true
        } label: {
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
        .buttonStyle(.plain)
        .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
    }

    // MARK: - Upgrade CTA

    /// Native upsell row (iCloud+ pattern): white card, Settings-style icon
    /// squircle, regular text colors and a soft tinted "Upgrade" capsule.
    /// With an eligible yearly trial the headline sells the trial instead
    /// (user decision 2026-10-19); subtitle and badge stay.
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
                    upgradeTitle
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    // iCloud sync is a free feature since 2026-07-28 and the
                    // scanner is unlimited for everyone since 2026-10-19 —
                    // the upsell sells ad-free scanning, not more scans.
                    Text("All nutrients, ad-free scanner & full history")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text("Upgrade")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accentDeep)
                    .badgeFit()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.accentSoft))
            }
            .settingsRowPadding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassCard(cornerRadius: Theme.cornerRadius)
        .task {
            await PaywallQuotesCache.prefetch(settings: settings)
            trialDays = PaywallQuotesCache.cached?[.yearly]?.trialDays
        }
    }

    private var upgradeTitle: Text {
        let quote = PaywallPlanQuote(price: "", trialDays: trialDays)
        if let trial = quote.trialLabel(locale: locale) {
            return Text("Try Premium free for \(trial)")
        }
        return Text("Try Premium")
    }
}
