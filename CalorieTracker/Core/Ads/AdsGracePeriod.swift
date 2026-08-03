import Foundation

/// Install-day ad holiday (user decision 2026-08-03): no ads of any kind for
/// the first 24 hours after the first launch. Enforced in one place —
/// `AdsConfig.shouldShowAds` — so banners and the rewarded scan gate all obey
/// it automatically.
///
/// The anchor lives in UserDefaults, deliberately not in SwiftData: like the
/// review-prompt state, this is a per-device courtesy — a fresh install on a
/// second device gets its own quiet day and never syncs through CloudKit.
enum AdsGracePeriod {
    static let duration: TimeInterval = 24 * 60 * 60
    private static let firstLaunchKey = "ads.firstLaunchAt"

    /// True while the install-day grace is still running. Seeds the anchor on
    /// first read, so legacy installs start their day from the first launch
    /// of a build with this feature.
    static var isActive: Bool {
        Date().timeIntervalSince(firstLaunchAt) < duration
    }

    private static var firstLaunchAt: Date {
        let defaults = UserDefaults.standard
        if let date = defaults.object(forKey: firstLaunchKey) as? Date { return date }
        let now = Date()
        defaults.set(now, forKey: firstLaunchKey)
        return now
    }

    #if DEBUG
    /// Settings → Test: fast-forward past the ad-free day.
    static func debugSkip() {
        UserDefaults.standard.set(
            Date(timeIntervalSinceNow: -duration - 60), forKey: firstLaunchKey
        )
    }

    /// Settings → Test: restart the ad-free day from now.
    static func debugReset() {
        UserDefaults.standard.set(Date(), forKey: firstLaunchKey)
    }
    #endif
}
