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
        try? context.delete(model: Product.self)
        try? context.delete(model: DiaryEntry.self)

        settings.calorieGoal = 2000
        settings.proteinGoal = 150
        settings.fatGoal = 67
        settings.carbGoal = 200
        settings.enabledNutrients = NutrientCatalog.all.map(\.id)
            .filter { NutrientCatalog.defaultEnabled.contains($0) }
        settings.nutrientGoalOverrides = [:]
        settings.nutrientTrackingLog = []
        settings.unitSystem = .metric
        settings.netCarbsEnabled = false
        settings.notificationsEnabled = false
        settings.reminderTimesMinutes = []
        settings.iCloudSyncEnabled = false
        settings.scanCount = 0
        settings.isPremium = false
        settings.onboardingCompleted = true

        SettingsReminderScheduler.cancelAll()
        try? context.save()
    }
}
