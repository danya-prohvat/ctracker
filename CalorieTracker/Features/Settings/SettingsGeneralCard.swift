import SwiftUI
import SwiftData

/// "General" card: language picker row, the single reminders toggle — it
/// drives both the smart meal reminders (`MealReminderScheduler`) and the
/// re-engagement series (`ReengagementNotificationService`), user decision
/// 2026-07-21 — and the iCloud sync toggle.
struct SettingsGeneralCard: View {
    @Environment(\.modelContext) private var context

    let settings: UserSettings

    @State private var showLanguagePicker = false

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
    }

    // MARK: - Rows

    private var languageRow: some View {
        Button {
            showLanguagePicker = true
        } label: {
            HStack(spacing: 5) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Language")
                        .font(.callout)
                        .foregroundStyle(Theme.textPrimary)
                    if AppLanguage.needsRestart(chosen: settings.languageCode) {
                        Text("Applies after restarting the app")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
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
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { settings.notificationsEnabled },
            set: { newValue in
                if newValue {
                    MealReminderScheduler.requestAuthorization { granted in
                        settings.notificationsEnabled = granted
                        try? context.save()
                        guard granted else { return }
                        Task { @MainActor in
                            MealReminderScheduler.reschedule(in: context)
                            ReengagementNotificationService.reschedule(in: context)
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
