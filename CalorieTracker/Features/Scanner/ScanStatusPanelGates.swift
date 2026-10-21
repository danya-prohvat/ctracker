import SwiftUI

/// Monetization state of the scan flow (user decision 2026-09-28): the
/// opt-in "Watch ad" offer that holds a found product back. Split out of
/// `ScanStatusPanel` for the file-size limit; its actions live in
/// `ScanActionBar`.
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
}

#Preview {
    ZStack {
        Theme.scanBackground.ignoresSafeArea()
        ScanStatusPanel(phase: .rewardOffer)
    }
}
