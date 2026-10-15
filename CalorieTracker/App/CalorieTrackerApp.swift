import SwiftUI
import SwiftData

@main
struct CalorieTrackerApp: App {
    let container: ModelContainer

    init() {
        // Billing SDK from process start, so out-of-app transactions (Ask to
        // Buy, renewals, refunds) are observed at once (fixed 2026-10-15).
        PurchasesBootstrap.configureIfNeeded()
        // The ad-free install day starts at the first launch, not at the first
        // ad-bearing screen (fixed 2026-10-15).
        AdsGracePeriod.seedFirstLaunchIfNeeded()
        #if DEBUG
        // `-initializeCloudKitSchema 1`: push the full schema to CloudKit
        // Development before deploying it to Production (see the type).
        CloudSchemaInitializer.runIfRequested()
        #endif
        let schema = Schema(versionedSchema: AppSchemaV1.self)
        // CloudKit-backed store only when the user enabled iCloud sync — a free
        // feature, no premium required (user decision 2026-07-28). Mirrored to
        // UserDefaults (see CloudSync); the toggle takes effect on the next
        // launch. If the cloud store can't open (capability missing, iCloud
        // unavailable), fall back to local instead of crashing.
        if CloudSync.activeThisLaunch,
           let cloud = try? Self.makeContainer(schema: schema, cloud: true) {
            container = cloud
            CloudSync.markCloudStoreOpened()
            return
        }
        do {
            container = try Self.makeContainer(schema: schema, cloud: false)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    private static func makeContainer(schema: Schema, cloud: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: cloud ? .private(CloudSync.containerID) : .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: [configuration]
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
