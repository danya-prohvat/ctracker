import SwiftUI
import SwiftData
import UIKit

/// "General" card: language picker row, the single reminders toggle — it
/// drives both the smart meal reminders (`MealReminderScheduler`) and the
/// re-engagement series (`ReengagementNotificationService`), user decision
/// 2026-07-21 — and the iCloud sync toggle.
struct SettingsGeneralCard: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL

    let settings: UserSettings

    @State private var showLanguagePicker = false
    @State private var showNotificationsDenied = false

    var body: some View {
        VStack(spacing: 0) {
            languageRow
            SettingsRowDivider()
            remindersRow
            SettingsRowDivider()
            iCloudRow
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerSheet(
                selected: SettingsLanguage(code: settings.languageCode),
                onSelect: apply
            )
        }
        .alert("Notifications are off", isPresented: $showNotificationsDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow notifications in Settings to get reminders.")
        }
    }

    // MARK: - Rows

    private var languageRow: some View {
        Button {
            showLanguagePicker = true
        } label: {
            HStack(spacing: 5) {
                Text("Language")
                    .font(.callout)
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 12)
                SettingsLanguage(code: settings.languageCode).title
                    .font(.subheadline)
                    .foregroundStyle(Theme.textTertiary)
                SettingsRowChevron()
            }
            .settingsRowPadding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var remindersRow: some View {
        HStack(spacing: 12) {
            Text("Reminders")
                .font(.callout)
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
            Toggle(isOn: notificationsBinding) { Text("Reminders") }
                .labelsHidden()
                .tint(Theme.accent)
        }
        .settingsRowPadding()
    }

    private var iCloudRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("iCloud sync")
                    .font(.callout)
                    .foregroundStyle(Theme.textPrimary)
                if CloudSync.needsRestart(settings: settings) {
                    Text("Applies after restarting the app")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            Spacer(minLength: 0)
            Toggle(isOn: iCloudBinding) { Text("iCloud sync") }
                .labelsHidden()
                .tint(Theme.accent)
        }
        .settingsRowPadding()
    }

    // MARK: - Actions

    private func apply(_ language: SettingsLanguage) {
        settings.languageCode = language.code
        if let code = language.code {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        try? context.save()
        // Pending notifications were baked in the previous language — replan
        // both series right away so they fire in the newly chosen one.
        MealReminderScheduler.reschedule(in: context)
        ReengagementNotificationService.reschedule(in: context)
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { settings.notificationsEnabled },
            set: { newValue in
                if newValue {
                    MealReminderScheduler.authorizationStatus { status in
                        // Already denied in iOS Settings: a new request would
                        // fail silently and the toggle would just snap back —
                        // explain and link to Settings instead (same standard
                        // as the scanner's camera-denied screen).
                        if status == .denied {
                            showNotificationsDenied = true
                            return
                        }
                        MealReminderScheduler.requestAuthorization { granted in
                            settings.notificationsEnabled = granted
                            try? context.save()
                            guard granted else { return }
                            Task { @MainActor in
                                MealReminderScheduler.reschedule(in: context)
                                ReengagementNotificationService.reschedule(in: context)
                            }
                        }
                    }
                } else {
                    settings.notificationsEnabled = false
                    MealReminderScheduler.cancelAll()
                    ReengagementNotificationService.cancelAll()
                    try? context.save()
                }
            }
        )
    }

    private var iCloudBinding: Binding<Bool> {
        Binding(
            get: { settings.iCloudSyncEnabled },
            set: { newValue in
                settings.iCloudSyncEnabled = newValue
                try? context.save()
                // The store is rebuilt on the next launch (see CloudSync);
                // the row shows the restart footnote until then.
                CloudSync.refresh(in: context)
            }
        )
    }
}
