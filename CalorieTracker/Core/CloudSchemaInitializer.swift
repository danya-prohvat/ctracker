#if DEBUG
import CloudKit
import CoreData
import SwiftData

/// DEBUG `-initializeCloudKitSchema 1`: pushes the COMPLETE record schema of
/// `AppSchemaV1` to the CloudKit Development environment, so it can then be
/// promoted with "Deploy Schema Changes" in the CloudKit Console.
///
/// Why not rely on the normal sync: CloudKit creates a field only when a
/// record carrying a value for it is exported. Optional fields that are still
/// nil everywhere (`Product.servingAmount`, `UserSettings.profile*`,
/// `dailyScanDayKey`) never reach the schema that way, and the first
/// production record with such a value would then be rejected.
/// `initializeCloudKitSchema` uploads every entity and attribute regardless of
/// data. Runs against a throwaway store in Caches; the app's own store is
/// untouched. Debug builds target Development automatically.
enum CloudSchemaInitializer {
    static func runIfRequested() {
        guard UserDefaults.standard.bool(forKey: "initializeCloudKitSchema") else { return }
        Task.detached(priority: .userInitiated) {
            guard await waitForAccount() else { return }
            run()
        }
    }

    /// Right after launch CloudKit often reports `.temporarilyUnavailable`
    /// for a few seconds; `initializeCloudKitSchema` fails hard on that. Poll
    /// until the account is `.available` (up to ~60 s).
    private static func waitForAccount() async -> Bool {
        let cloud = CKContainer(identifier: CloudSync.containerID)
        for attempt in 1...30 {
            let status = try? await cloud.accountStatus()
            if status == .available {
                print("[CloudSchemaInitializer] iCloud account available (attempt \(attempt))")
                return true
            }
            print("[CloudSchemaInitializer] waiting for iCloud account… status=\(status.map { "\($0.rawValue)" } ?? "error")")
            try? await Task.sleep(for: .seconds(2))
        }
        print("[CloudSchemaInitializer] ❌ iCloud account never became available")
        return false
    }

    private static func run() {
        guard let model = NSManagedObjectModel.makeManagedObjectModel(for: AppSchemaV1.models) else {
            print("[CloudSchemaInitializer] ❌ could not build NSManagedObjectModel from AppSchemaV1")
            return
        }
        let url = URL.cachesDirectory.appending(path: "CloudSchemaInit.sqlite")
        let description = NSPersistentStoreDescription(url: url)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: CloudSync.containerID
        )
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        let container = NSPersistentCloudKitContainer(name: "CloudSchemaInit", managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError {
            print("[CloudSchemaInitializer] ❌ store failed to load: \(loadError)")
            return
        }
        do {
            try container.initializeCloudKitSchema(options: [])
            let names = model.entities.compactMap(\.name).sorted().joined(separator: ", ")
            print("[CloudSchemaInitializer] ✅ schema pushed to Development for: \(names)")
        } catch {
            print("[CloudSchemaInitializer] ❌ initializeCloudKitSchema failed: \(error)")
        }
        removeStore(at: url, coordinator: container.persistentStoreCoordinator)
    }

    private static func removeStore(at url: URL, coordinator: NSPersistentStoreCoordinator) {
        for store in coordinator.persistentStores {
            try? coordinator.remove(store)
        }
        try? coordinator.destroyPersistentStore(at: url, type: .sqlite)
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(at: URL(filePath: url.path + suffix))
        }
    }
}
#endif
