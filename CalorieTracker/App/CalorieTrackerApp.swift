import SwiftUI
import SwiftData

@main
struct CalorieTrackerApp: App {
    let container: ModelContainer

    init() {
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
