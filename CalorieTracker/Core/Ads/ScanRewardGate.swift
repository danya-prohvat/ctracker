import SwiftData

/// The rewarded-ad toll on barcode scanning (user decision 2026-08-03): from
/// the second successful scan on, free users watch a rewarded ad before the
/// scan result is revealed. The very first scan is ad-free; premium and the
/// install-day grace skip ads entirely (both via `AdsConfig.shouldShowAds`).
@MainActor
enum ScanRewardGate {
    /// Called when the scan flow opens, so the ad is loading while the user
    /// aims the camera. No-op when the gate would not apply.
    static func preloadIfNeeded(context: ModelContext) async {
        guard applies(context: context) else { return }
        await RewardedAdManager.shared.preload()
    }

    /// Runs `reveal` behind the rewarded ad when the gate applies and an ad
    /// is loaded, or immediately otherwise — the ad must never block or lose
    /// the scan result.
    static func present(context: ModelContext, reveal: @escaping () -> Void) {
        if applies(context: context),
           RewardedAdManager.shared.show(onDismiss: reveal) {
            return
        }
        reveal()
    }

    private static func applies(context: ModelContext) -> Bool {
        AdsConfig.shouldShowScanReward(settings: UserSettings.current(in: context))
    }
}
