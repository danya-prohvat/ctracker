import SwiftData

/// What the next successful barcode scan costs (user decision 2026-10-19).
enum ScanToll: Equatable {
    /// Premium or the install-day grace: no counters, no ads.
    case none
    /// Free user with ad-free scans still left today.
    case freeToday(left: Int)
    /// Today's ad-free scans are spent: each further scan sits behind the
    /// opt-in "Watch ad" offer.
    case ad
}

/// The rewarded-ad toll on barcode scanning (user decision 2026-10-19,
/// replaces the welcome pool + daily cap of 2026-09-28): scanning is never
/// limited for anyone. A free user past the install-day grace gets
/// `dailyAdFreeScans` successful scans per local day without ads; every
/// further scan that day is held behind the opt-in "Watch ad" offer, as AdMob
/// requires for rewarded ads — the reward is the scan itself. Premium and the
/// grace day skip ads entirely (`AdsConfig.shouldShowAds`).
@MainActor
enum ScanRewardGate {
    /// Ad-free successful scans per local day for a free user past the grace.
    nonisolated static let dailyAdFreeScans = 3

    /// The day counter is read as zero whenever its day key is not today.
    nonisolated static func toll(settings: UserSettings) -> ScanToll {
        guard AdsConfig.shouldShowAds(settings: settings) else { return .none }
        let left = dailyAdFreeScans - usedToday(settings)
        return left > 0 ? .freeToday(left: left) : .ad
    }

    /// The single writer of the day counter — one call per successful OFF
    /// lookup (`AddFoodScanFlow`). Premium and the grace day never count; the
    /// counter restarts on the first scan of a new day.
    nonisolated static func recordSuccessfulScan(settings: UserSettings) {
        guard toll(settings: settings) != .none else { return }
        if settings.dailyScanDayKey != DayKey.today {
            settings.dailyScanDayKey = DayKey.today
            settings.dailyScanCount = 0
        }
        settings.dailyScanCount += 1
    }

    /// Called when the scan flow opens, so the ad is loading while the user
    /// aims the camera. Also warms up on the last ad-free scan of the day:
    /// a lookup usually beats a cold ad load, and an ad that isn't ready by
    /// then reveals the next scan for free instead of being offered.
    static func preloadIfNeeded(context: ModelContext) async {
        switch toll(settings: UserSettings.current(in: context)) {
        case .ad, .freeToday(left: 1):
            await RewardedAdManager.shared.preload()
        default:
            return
        }
    }

    /// True when a successful lookup should stop at the "Watch ad" offer: the
    /// scan costs an ad and one is actually loaded. No ad ready = the result
    /// is revealed for free — an ad must never block or lose a scan.
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
        toll(settings: UserSettings.current(in: context)) == .ad
    }

    private nonisolated static func usedToday(_ settings: UserSettings) -> Int {
        settings.dailyScanDayKey == DayKey.today ? settings.dailyScanCount : 0
    }
}
