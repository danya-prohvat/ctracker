import UIKit
#if canImport(GoogleMobileAds)
import GoogleMobileAds

/// Loads and shows rewarded ads. Not wired to any screen yet — placements are
/// a separate product decision. Rewarded ads must be opt-in: check `isReady`
/// to enable the trigger button, call `show(onReward:)` on tap; the next ad
/// preloads itself after each dismissal.
@MainActor
final class RewardedAdManager: NSObject, FullScreenContentDelegate {
    static let shared = RewardedAdManager()

    private var rewardedAd: RewardedAd?

    /// True when an ad is loaded and can be shown right now.
    var isReady: Bool { rewardedAd != nil }

    func preload() async {
        guard rewardedAd == nil else { return }
        AdMobService.startIfNeeded()
        rewardedAd = try? await RewardedAd.load(
            with: AdsConfig.rewardedAdUnitID,
            request: Request()
        )
        rewardedAd?.fullScreenContentDelegate = self
    }

    /// Presents the loaded ad; `onReward` fires only when the user actually
    /// earns the reward (watched enough of the ad — closing early earns
    /// nothing). Returns false (and does nothing) when no ad is ready.
    @discardableResult
    func show(onReward: @escaping (_ amount: Int) -> Void) -> Bool {
        guard let rewardedAd, let presenter = AdPresenter.topViewController else {
            return false
        }
        rewardedAd.present(from: presenter) {
            onReward(rewardedAd.adReward.amount.intValue)
        }
        return true
    }

    // MARK: - FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        rewardedAd = nil
        Task { await preload() }
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        rewardedAd = nil
    }
}
#else
/// SDK-less stub so the project builds without GoogleMobileAds (same pattern
/// as `StubPurchaseService` for RevenueCat).
@MainActor
final class RewardedAdManager {
    static let shared = RewardedAdManager()

    var isReady: Bool { false }

    func preload() async {}

    @discardableResult
    func show(onReward: @escaping (_ amount: Int) -> Void) -> Bool { false }
}
#endif
