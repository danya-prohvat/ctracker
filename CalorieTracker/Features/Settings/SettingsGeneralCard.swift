import SwiftUI
import SwiftData

/// "General" card: language picker row, meal-reminders toggle (label pushes
/// the times editor while enabled) and the premium-gated iCloud sync toggle.
struct SettingsGeneralCard: View {
    @Environment(\.modelContext) private var context

    let settings: UserSettings
    let onUpgrade: () -> Void

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
        .confirmationDialog(
            "Language",
            isPresented: $showLanguagePicker,
            titleVisibility: .visible
        ) {
            ForEach(SettingsLanguage.allCases) { language in
                Button {
                    apply(language)
                } label: {
                    language.title
                }
            }
        } message: {
            Text("Restart the app to apply the language.")
        }
    }

    // MARK: - Rows

    private var languageRow: some View {
        Button {
            showLanguagePicker = true
        } label: {
            HStack(spacing: 5) {
                Text("Language")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 12)
                SettingsLanguage(code: settings.languageCode).title
                    .font(.system(size: 15))
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
            if settings.notificationsEnabled {
                NavigationLink {
                    SettingsRemindersView(settings: settings)
                } label: {
                    HStack(spacing: 5) {
                        Text("Reminders")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textPrimary)
                        SettingsRowChevron()
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Text("Reminders")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
            }
            Toggle(isOn: notificationsBinding) { Text("Reminders") }
                .labelsHidden()
                .tint(Theme.accent)
        }
        .settingsRowPadding()
    }

    private var iCloudRow: some View {
        HStack(spacing: 12) {
            Text("iCloud sync")
                .font(.system(size: 16))
                .foregroundStyle(Theme.textPrimary)
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
                    SettingsReminderScheduler.requestAuthorization { granted in
                        settings.notificationsEnabled = granted
                        if granted {
                            SettingsReminderScheduler.reschedule(
                                minutesList: settings.reminderTimesMinutes
                            )
                        }
                        try? context.save()
                    }
                } else {
                    settings.notificationsEnabled = false
                    SettingsReminderScheduler.cancelAll()
                    try? context.save()
                }
            }
        )
    }

    private var iCloudBinding: Binding<Bool> {
        Binding(
            get: { settings.iCloudSyncEnabled },
            set: { newValue in
                if newValue && !PremiumGate.isUnlocked(.icloudSync, settings: settings) {
                    onUpgrade()
                    return
                }
                // TODO(integration): switching the actual CloudKit container happens
                // in a later pass — for now only the preference is stored.
                settings.iCloudSyncEnabled = newValue
                try? context.save()
            }
        )
    }
}
