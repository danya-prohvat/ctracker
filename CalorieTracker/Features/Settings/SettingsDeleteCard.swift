import SwiftUI
import SwiftData

/// Destructive "Delete all data" card with the native confirmation alert
/// (prototype: centered dialog with Cancel / destructive Delete).
struct SettingsDeleteCard: View {
    @Environment(\.modelContext) private var context

    let settings: UserSettings

    @State private var showConfirm = false

    var body: some View {
        Button {
            showConfirm = true
        } label: {
            Text("Delete all data")
                .font(.headline)
                .foregroundStyle(Theme.destructive)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassCard(cornerRadius: Theme.cornerRadius)
        .alert("Delete all data?", isPresented: $showConfirm) {
            Button("Delete", role: .destructive) { deleteAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            if settings.iCloudSyncEnabled {
                Text("This erases all products, diary entries and settings on this device and in iCloud.")
            } else {
                Text("This erases all products, diary entries and settings on this device.")
            }
        }
    }

    /// Wipe everything and return settings to first-launch defaults, except
    /// `onboardingCompleted` — onboarding shows only once (spec §8).
    private func deleteAllData() {
        // Object-by-object, not `context.delete(model:)`: batch deletes bypass
        // the CloudKit export pipeline, so the synced copies would survive in
        // iCloud and merge right back on the next launch.
        for product in (try? context.fetch(FetchDescriptor<Product>())) ?? [] {
            context.delete(product)
        }
        for entry in (try? context.fetch(FetchDescriptor<DiaryEntry>())) ?? [] {
            context.delete(entry)
        }

        settings.calorieGoal = 2000
        settings.proteinGoal = 150
        settings.fatGoal = 67
        settings.carbGoal = 200
        settings.enabledNutrients = NutrientCatalog.all.map(\.id)
            .filter { NutrientCatalog.defaultEnabled.contains($0) }
        settings.nutrientGoalOverrides = [:]
        settings.nutrientTrackingLog = []
        settings.unitSystem = UserSettings.defaultUnitSystem
        settings.netCarbsEnabled = false
        settings.notificationsEnabled = false
        settings.iCloudSyncEnabled = false
        settings.scanCount = 0
        settings.isPremium = false
        settings.onboardingCompleted = true

        MealReminderScheduler.cancelAll()
        ReengagementNotificationService.cancelAll()
        try? context.save()
        CloudSync.refresh(in: context)
    }
}
