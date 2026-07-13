import Foundation
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// Starts the Google Mobile Ads SDK lazily, right before the first ad loads,
/// keeping app launch free of ad-SDK work. Mirrors the RevenueCat pattern:
/// without the SDK the project still builds and the call is a no-op.
///
/// TODO(release): before shipping to EEA/UK, gather GDPR consent via the UMP
/// SDK (`ConsentInformation` / `ConsentForm`, ships inside the GoogleMobileAds
/// package) before starting the SDK — requires a consent message configured
/// in the AdMob console first.
@MainActor
enum AdMobService {
    private static var isStarted = false

    static func startIfNeeded() {
        guard !isStarted else { return }
        isStarted = true
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start()
        #endif
    }
}
