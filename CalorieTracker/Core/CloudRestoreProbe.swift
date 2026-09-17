import CloudKit
import CoreData
import SwiftData

/// Reinstall probe: does this iCloud account hold a finished onboarding or
/// real data worth restoring? RootView uses it to skip onboarding on reinstall
/// (user decision 2026-09-12, reworked 2026-09-17).
///
/// The earlier check — "does the `com.apple.coredata.cloudkit.zone` zone
/// exist" — raced against the app itself: opening the cloud store creates
/// that zone, so from the second install on the probe always said "returning
/// user", even after the account's data was wiped. A zone is also created by
/// a 10-second visit that never finished onboarding. The signal is now the
/// imported records: wait for SwiftData's first CloudKit import to finish,
/// then look at what actually landed in the local store.
enum CloudRestoreProbe {

    /// Waits (up to `timeoutSeconds`) for the first CloudKit import and returns
    /// true as soon as restored data shows up locally. No account, offline,
    /// an import that brought nothing, or a timeout → false, and the caller
    /// runs normal onboarding: better to onboard a returning user once more
    /// than to strand a new one on an empty Today.
    @MainActor
    static func waitForCloudData(in context: ModelContext, timeoutSeconds: Double = 8) async -> Bool {
        let container = CKContainer(identifier: CloudSync.containerID)
        guard let status = try? await container.accountStatus(),
              status == .available else { return false }

        let importFlag = ImportFlag()
        let listener = Task { @MainActor in
            let events = NotificationCenter.default.notifications(
                named: NSPersistentCloudKitContainer.eventChangedNotification)
            for await note in events {
                guard let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                        as? NSPersistentCloudKitContainer.Event,
                      event.type == .import, event.endDate != nil else { continue }
                importFlag.finishedAt = Date()
                return
            }
        }
        defer { listener.cancel() }

        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while Date() < deadline {
            if hasRestoredData(in: context) { return true }
            // Merged objects reach the main context shortly after the import
            // event; give them a short grace period before concluding "empty".
            if let finished = importFlag.finishedAt, Date().timeIntervalSince(finished) > 1.5 {
                return false
            }
            try? await Task.sleep(for: .milliseconds(300))
        }
        return hasRestoredData(in: context)
    }

    /// True when the local store already holds a finished onboarding or any
    /// product / diary entry — i.e. something a returning user would miss.
    @MainActor
    static func hasRestoredData(in context: ModelContext) -> Bool {
        let settings = (try? context.fetch(FetchDescriptor<UserSettings>())) ?? []
        if settings.contains(where: { $0.onboardingCompleted }) { return true }
        var products = FetchDescriptor<Product>()
        products.fetchLimit = 1
        if let hit = try? context.fetch(products), !hit.isEmpty { return true }
        var entries = FetchDescriptor<DiaryEntry>()
        entries.fetchLimit = 1
        if let hit = try? context.fetch(entries), !hit.isEmpty { return true }
        return false
    }

    /// Main-actor mailbox for the import listener task.
    @MainActor
    private final class ImportFlag {
        var finishedAt: Date?
    }
}
