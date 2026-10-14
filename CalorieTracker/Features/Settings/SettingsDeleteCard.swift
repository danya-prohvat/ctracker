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
            // What actually gets wiped depends on the store THIS launch runs
            // with, not the toggle — the toggle only applies after a restart,
            // and per-object deletes export to iCloud only from a cloud store.
            if CloudSync.cloudStoreOpened {
                Text("This erases all products, diary entries and settings on this device and in iCloud.")
            } else {
                Text("This erases all products, diary entries and settings on this device.")
            }
        }
    }

    /// Wipe the *data* (products, diary, goals, body profile, nutrient
    /// tracking) and keep the device/account *preferences*: `onboardingCompleted`
    /// (onboarding shows only once, spec §8), `isPremium` (mirrors the paid
    /// entitlement), `iCloudSyncEnabled` (see below), `languageCode`,
    /// `unitSystem` and the free-scan counters (fix 2026-10-10: resetting
    /// them handed out a fresh welcome pool of 10 scans per wipe, and the
    /// units snapped to the device default instead of the user's choice).
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
        settings.netCarbsEnabled = false
        settings.notificationsEnabled = false
        settings.clearBodyProfile()
        // iCloudSyncEnabled intentionally survives: it's an explicit user
        // choice. Re-enabling it here would silently resurrect the wiped data
        // from iCloud on the next launch (and re-upload future data) for a
        // user who deliberately opted out of sync.
        // isPremium and the scan counters intentionally survive — wiping local
        // data neither cancels the subscription nor refills the free quota.
        settings.onboardingCompleted = true

        MealReminderScheduler.cancelAll()
        ReengagementNotificationService.cancelAll()
        try? context.save()
        CloudSync.refresh(in: context)
    }
}
