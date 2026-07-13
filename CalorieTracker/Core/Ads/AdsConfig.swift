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

    /// Ads are a free-tier experience: premium removes them everywhere.
    /// Views ask this single gate, never `isPremium` directly.
    static func shouldShowAds(settings: UserSettings) -> Bool {
        !PremiumGate.isPremium(settings: settings)
    }
}
