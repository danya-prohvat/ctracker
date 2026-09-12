import CloudKit

/// First-launch probe: does this iCloud account already hold app data?
/// SwiftData mirrors everything into the fixed `com.apple.coredata.cloudkit.zone`
/// record zone, so the zone's existence is an authoritative "returning user"
/// signal — one cheap zone fetch, no record download. RootView uses it to skip
/// onboarding on reinstall (user decision 2026-09-12); the data itself streams
/// in through the normal SwiftData import right after.
enum CloudRestoreProbe {
    /// The zone name NSPersistentCloudKitContainer/SwiftData always mirrors into.
    private static let zoneName = "com.apple.coredata.cloudkit.zone"

    /// True when the private database already has the SwiftData zone. Any
    /// failure (no account, offline, timeout) returns false — the caller falls
    /// back to normal onboarding: better to onboard a returning user once more
    /// than to strand a new one on an empty Today.
    static func hasCloudData(timeoutSeconds: Double = 5) async -> Bool {
        let container = CKContainer(identifier: CloudSync.containerID)
        guard let status = try? await container.accountStatus(),
              status == .available else { return false }
        let zoneID = CKRecordZone.ID(zoneName: zoneName)
        return await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                (try? await container.privateCloudDatabase.recordZone(for: zoneID)) != nil
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(timeoutSeconds))
                return false
            }
            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }
    }
}
