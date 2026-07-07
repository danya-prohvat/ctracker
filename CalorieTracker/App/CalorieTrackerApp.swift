import SwiftUI
import SwiftData

@main
struct CalorieTrackerApp: App {
    let container: ModelContainer

    init() {
        do {
            // Local store for now. CloudKit sync can be enabled later by adding the
            // CloudKit capability + entitlement and switching the configuration to
            // `cloudKitDatabase: .automatic` (models are already CloudKit-friendly:
            // all attributes have defaults, no `.unique` constraints).
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(
                for: Product.self, DiaryEntry.self, UserSettings.self,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
