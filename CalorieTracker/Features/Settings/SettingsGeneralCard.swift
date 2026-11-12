import SwiftUI
import SwiftData

/// "General" card (restyled 2026-11-12: icon tiles, no switches on the root):
/// units and appearance as menu pickers, language as a sheet, and
/// Reminders / iCloud sync as value rows (`On` / `Off` + chevron) that push
/// their own screens — the switch lives there, next to an explanation of
/// what it does. Reminders drive both the smart meal reminders
/// (`MealReminderScheduler`) and the re-engagement series
/// (`ReengagementNotificationService`), user decision 2026-07-21.
struct SettingsGeneralCard: View {
    @Environment(\.modelContext) private var context
    @Environment(\.locale) private var locale

    let settings: UserSettings

    @State private var showLanguagePicker = false

    var body: some View {
        VStack(spacing: 0) {
            SettingsUnitsRow(settings: settings)
            SettingsRowDivider()
            languageRow
            SettingsRowDivider()
            SettingsAppearanceRow()
            SettingsRowDivider()
            remindersRow
            SettingsRowDivider()
            iCloudRow
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
        .adaptiveSheet(isPresented: $showLanguagePicker) {
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
            SettingsRowLabel(
                icon: "globe", tint: Theme.tileSlate, title: "Language",
                value: SettingsLanguage(code: settings.languageCode).title
            )
        }
        .buttonStyle(.plain)
    }

    private var remindersRow: some View {
        NavigationLink {
            RemindersSettingsView(settings: settings)
        } label: {
            SettingsRowLabel(
                icon: "bell.badge", tint: Theme.tileCoral, title: "Reminders",
                subtitle: RemindersSchedule.summary(locale: locale),
                value: onOff(settings.notificationsEnabled)
            )
        }
        .buttonStyle(.plain)
    }

    private var iCloudRow: some View {
        NavigationLink {
            CloudSyncSettingsView(settings: settings)
        } label: {
            SettingsRowLabel(
                icon: "icloud", tint: Theme.tileTeal, title: "iCloud sync",
                subtitle: CloudSync.needsRestart(settings: settings)
                    ? Text("Applies after restarting the app") : nil,
                value: onOff(settings.iCloudSyncEnabled)
            )
        }
        .buttonStyle(.plain)
    }

    private func onOff(_ isOn: Bool) -> Text {
        isOn ? Text("On") : Text("Off")
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
}
