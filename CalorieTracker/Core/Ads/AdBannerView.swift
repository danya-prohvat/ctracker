import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// Compact AdMob banner in a full-width app card (matches the other settings
/// cards); the ad itself is the fixed 320×50 standard size, centered —
/// deliberately NOT adaptive: adaptive/large sizes reserve tall slots that
/// don't fit the settings layout.
/// Free users only; premium users (and builds without the SDK) get nothing.
struct AdBannerView: View {
    let settings: UserSettings

    #if canImport(GoogleMobileAds)
    var body: some View {
        if AdsConfig.shouldShowAds(settings: settings) {
            BannerViewContainer(adSize: AdSizeBanner)
                .frame(width: AdSizeBanner.size.width, height: AdSizeBanner.size.height)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: Theme.cornerRadius)
                .task { AdMobService.startIfNeeded() }
        }
    }
    #else
    var body: some View {
        EmptyView()
    }
    #endif
}

#if canImport(GoogleMobileAds)
/// UIKit bridge for `BannerView` (per Google's SwiftUI sample). The SDK
/// resolves the presenting view controller automatically.
private struct BannerViewContainer: UIViewRepresentable {
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = AdsConfig.bannerAdUnitID
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
#endif
