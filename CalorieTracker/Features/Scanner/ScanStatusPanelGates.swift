import SwiftUI

/// Monetization states of the scan flow (user decision 2026-09-28): the
/// opt-in "Watch ad" offer that holds a found product back, and the daily
/// free-scan limit. Split out of `ScanStatusPanel` for the file-size limit;
/// the actions for both live in `ScanActionBar`.
extension ScanStatusPanel {
    /// The product is found. AdMob requires rewarded ads to be opt-in, so the
    /// result waits for an explicit "Watch ad" tap in the action bar.
    var rewardOffer: some View {
        VStack(spacing: 16) {
            statusCircle {
                Image(systemName: "checkmark")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.scanLine)
            }
            message(
                title: "Product found",
                body: "Watch a short ad to open it, or go Premium to scan ad-free.",
                maxWidth: 260
            )
        }
    }

    /// Today's free scans are spent; the limit resets with the local day.
    var limitReached: some View {
        VStack(spacing: 16) {
            statusCircle {
                Image(systemName: "hourglass")
                    .font(.title.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            message(
                title: "Daily scan limit reached",
                body: "You've used today's \(PremiumGate.dailyFreeScanLimit) free scans. Come back tomorrow, or go Premium for unlimited scanning.",
                maxWidth: 270
            )
        }
    }
}

#Preview {
    ZStack {
        Theme.scanBackground.ignoresSafeArea()
        VStack(spacing: 40) {
            ScanStatusPanel(phase: .rewardOffer)
            ScanStatusPanel(phase: .limitReached)
        }
    }
}
