import UIKit
#if canImport(GoogleMobileAds)
import GoogleMobileAds

/// Loads and shows interstitial ads. Not wired to any screen yet — placements
/// are a separate product decision. Usage: `await preload()` ahead of time,
/// then `show()` at a natural transition point; the next ad preloads itself
/// after each dismissal. Callers must respect `AdsConfig.shouldShowAds`.
@MainActor
final class InterstitialAdManager: NSObject, FullScreenContentDelegate {
    static let shared = InterstitialAdManager()

    private var interstitial: InterstitialAd?

    /// True when an ad is loaded and can be shown right now.
    var isReady: Bool { interstitial != nil }

    func preload() async {
        guard interstitial == nil else { return }
        AdMobService.startIfNeeded()
        interstitial = try? await InterstitialAd.load(
            with: AdsConfig.interstitialAdUnitID,
            request: Request()
        )
        interstitial?.fullScreenContentDelegate = self
    }

    /// Presents the loaded ad from the frontmost view controller.
    /// Returns false (and does nothing) when no ad is ready.
    @discardableResult
    func show() -> Bool {
        guard let interstitial, let presenter = AdPresenter.topViewController else {
            return false
        }
        interstitial.present(from: presenter)
        return true
    }

    // MARK: - FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitial = nil
        Task { await preload() }
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        interstitial = nil
    }
}
#else
/// SDK-less stub so the project builds without GoogleMobileAds (same pattern
/// as `StubPurchaseService` for RevenueCat).
@MainActor
final class InterstitialAdManager {
    static let shared = InterstitialAdManager()

    var isReady: Bool { false }

    func preload() async {}

    @discardableResult
    func show() -> Bool { false }
}
#endif
