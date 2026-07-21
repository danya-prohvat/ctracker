import Foundation
import SwiftData

/// Decides whether the SwiftData store is CloudKit-backed (premium feature).
///
/// The user's choice (`UserSettings.iCloudSyncEnabled`) lives inside the store
/// itself, but local-vs-cloud must be decided *before* the store opens — so
/// the effective state (toggle AND premium) is mirrored to UserDefaults and
/// read at the next launch. Flipping the toggle therefore takes effect on
/// restart; Settings shows a footnote while the states differ.
enum CloudSync {
    static let containerID = "iCloud.com.prxfitness.calorietracker"
    private static let mirrorKey = "iCloudSyncActive"

    /// What this launch actually runs with — read once at startup, before the
    /// container is created.
    static let activeThisLaunch = UserDefaults.standard.bool(forKey: mirrorKey)

    /// Effective desired state: the toggle counts only while premium is
    /// active, so sync never keeps working on a lapsed subscription.
    static func isDesired(settings: UserSettings) -> Bool {
        settings.iCloudSyncEnabled && PremiumGate.isPremium(settings: settings)
    }

    /// Recompute the mirror from settings. Call on every app activation and
    /// after the toggle changes. A lapsed premium also flips the stored
    /// toggle off, so the Settings row honestly shows sync as disabled.
    @MainActor
    static func refresh(in context: ModelContext) {
        let settings = UserSettings.current(in: context)
        if settings.iCloudSyncEnabled && !PremiumGate.isPremium(settings: settings) {
            settings.iCloudSyncEnabled = false
            try? context.save()
        }
        UserDefaults.standard.set(isDesired(settings: settings), forKey: mirrorKey)
    }

    /// True while the user's choice differs from what this launch runs with —
    /// drives the "applies after restart" footnote in Settings.
    static func needsRestart(settings: UserSettings) -> Bool {
        isDesired(settings: settings) != activeThisLaunch
    }
}
