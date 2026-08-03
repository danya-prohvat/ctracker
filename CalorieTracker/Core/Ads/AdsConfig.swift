import Foundation

/// Central AdMob configuration — the single place for ad unit IDs, mirroring
/// how `PurchasesConfig` holds the RevenueCat key.
///
/// DEBUG uses Google's official test units (always serve test ads, safe to
/// click — clicking your own live ads violates AdMob policy and risks the
/// account). Release uses the real units from the AdMob console
/// (banner_general / interstitial_general / rewarded_general). The AdMob
/// *app* ID lives in `Config/Info.plist` (`GADApplicationIdentifier`).
enum AdsConfig {
    #if DEBUG
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    static let bannerAdUnitID = "ca-app-pub-2939708793200469/2546026417"
    static let interstitialAdUnitID = "ca-app-pub-2939708793200469/6792393186"
    static let rewardedAdUnitID = "ca-app-pub-2939708793200469/8791870568"
    #endif

    /// Ads are a free-tier experience: premium removes them everywhere, and
    /// the first day after install is ad-free (`AdsGracePeriod`). Views ask
    /// this single gate, never `isPremium` directly.
    static func shouldShowAds(settings: UserSettings) -> Bool {
        !PremiumGate.isPremium(settings: settings) && !AdsGracePeriod.isActive
    }

    /// Rewarded gate for the barcode scanner (user decision 2026-08-03):
    /// every successful scan after the first shows a rewarded ad before the
    /// result is revealed. The very first scan stays ad-free, premium and the
    /// install-day grace skip ads entirely via `shouldShowAds`.
    static func shouldShowScanReward(settings: UserSettings) -> Bool {
        shouldShowAds(settings: settings) && settings.scanCount >= 1
    }
}
