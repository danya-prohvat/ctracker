import SwiftUI

/// Shown in the Calendar tab in place of the period stats when the whole visible
/// period is older than the free-tier 30-day history window (spec §9). Makes the
/// limit tangible and offers the upgrade instead of leaking locked-day averages.
struct CalendarHistoryLockedCard: View {
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: 48, height: 48)
                .background(Theme.accentSoft, in: Circle())

            VStack(spacing: 5) {
                Text("Unlock full history")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("The free plan shows the last 30 days. Upgrade to browse your whole diary.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onUnlock) {
                Text("Unlock history")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusButton)
                            .fill(Theme.accent)
                    )
            }
            .buttonStyle(.pressableCard)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 18)
    }
}

#Preview {
    ZStack {
        AppBackground()
        CalendarHistoryLockedCard(onUnlock: {})
            .padding(16)
    }
}
