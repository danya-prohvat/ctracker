import SwiftData

/// The rewarded-ad toll on barcode scanning (user decision 2026-08-03; opt-in
/// since 2026-09-28, as AdMob requires for rewarded ads): from the second
/// successful scan on, free users get a "Watch ad" offer before the result
/// is revealed — the reward is the scan itself. The very first scan is
/// ad-free; premium and the install-day grace skip ads entirely (both via
/// `AdsConfig.shouldShowAds`).
@MainActor
enum ScanRewardGate {
    /// Called when the scan flow opens, so the ad is loading while the user
    /// aims the camera. No-op when the gate would not apply.
    static func preloadIfNeeded(context: ModelContext) async {
        guard applies(context: context) else { return }
        await RewardedAdManager.shared.preload()
    }

    /// True when a successful lookup should stop at the "Watch ad" offer: the
    /// gate applies and an ad is actually loaded. No ad ready = the result is
    /// revealed for free — an ad must never block or lose a scan.
    static func shouldOffer(context: ModelContext) -> Bool {
        applies(context: context) && RewardedAdManager.shared.isReady
    }

    /// Shows the loaded ad and runs `reveal` once it is gone — closing early
    /// still reveals — or immediately when no ad can be presented after all.
    static func present(reveal: @escaping () -> Void) {
        if RewardedAdManager.shared.show(onDismiss: reveal) { return }
        reveal()
    }

    private static func applies(context: ModelContext) -> Bool {
        AdsConfig.shouldShowScanReward(settings: UserSettings.current(in: context))
    }
}
