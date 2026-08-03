import UIKit
#if canImport(GoogleMobileAds)
import GoogleMobileAds

/// Loads and shows rewarded ads. Wired to the barcode scanner: from the
/// second successful scan on, the scan flow preloads an ad on open and shows
/// it before revealing the lookup result (see `AdsConfig.shouldShowScanReward`).
/// Check `isReady` before calling `show` — a missing ad must never block the
/// flow it gates; the next ad preloads itself after each dismissal.
@MainActor
final class RewardedAdManager: NSObject, FullScreenContentDelegate {
    static let shared = RewardedAdManager()

    private var rewardedAd: RewardedAd?
    /// Continuation for the flow the ad interrupted; fires exactly once, on
    /// dismissal or on a failed presentation.
    private var onDismiss: (() -> Void)?

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

    /// Presents the loaded ad. `onReward` fires only when the user actually
    /// earns the reward (watched enough of the ad — closing early earns
    /// nothing); `onDismiss` fires once the ad is gone either way, so callers
    /// can resume the interrupted flow. Returns false (and does nothing) when
    /// no ad is ready.
    @discardableResult
    func show(
        onReward: ((_ amount: Int) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> Bool {
        guard let rewardedAd, let presenter = AdPresenter.topViewController else {
            return false
        }
        self.onDismiss = onDismiss
        rewardedAd.present(from: presenter) {
            onReward?(rewardedAd.adReward.amount.intValue)
        }
        return true
    }

    private func finish() {
        let continuation = onDismiss
        onDismiss = nil
        continuation?()
    }

    // MARK: - FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        rewardedAd = nil
        finish()
        Task { await preload() }
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        rewardedAd = nil
        finish()
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
    func show(
        onReward: ((_ amount: Int) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> Bool { false }
}
#endif
