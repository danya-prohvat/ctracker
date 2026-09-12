import Foundation
import SwiftData

/// Decides whether the SwiftData store is CloudKit-backed.
///
/// The user's choice (`UserSettings.iCloudSyncEnabled`) lives inside the store
/// itself, but local-vs-cloud must be decided *before* the store opens — so
/// the toggle is mirrored to UserDefaults and read at the next launch.
/// Flipping the toggle therefore takes effect on restart; Settings shows a
/// footnote while the states differ.
enum CloudSync {
    static let containerID = "iCloud.com.prxfitness.calorietracker"
    private static let mirrorKey = "iCloudSyncActive"

    /// What this launch actually runs with — read once at startup, before the
    /// container is created. No mirror yet (first launch after install) means
    /// the default: ON (user decision 2026-09-12).
    static let activeThisLaunch = (UserDefaults.standard.object(forKey: mirrorKey) as? Bool) ?? true

    /// Whether THIS launch actually opened the CloudKit-backed store — the
    /// mirror can be on while the cloud store failed to open (no iCloud
    /// account, capability missing) and the app silently fell back to local.
    /// Set once by `CalorieTrackerApp`; gates the reinstall-restore probe.
    private(set) static var cloudStoreOpened = false
    static func markCloudStoreOpened() { cloudStoreOpened = true }

    /// Recompute the mirror from settings. Call on every app activation and
    /// after the toggle changes.
    @MainActor
    static func refresh(in context: ModelContext) {
        let settings = UserSettings.current(in: context)
        UserDefaults.standard.set(settings.iCloudSyncEnabled, forKey: mirrorKey)
    }

    /// True while the user's choice differs from what this launch runs with —
    /// drives the "applies after restart" footnote in Settings.
    static func needsRestart(settings: UserSettings) -> Bool {
        settings.iCloudSyncEnabled != activeThisLaunch
    }
}
