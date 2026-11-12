import SwiftUI
import SwiftData
import UIKit

/// Pushed from Settings → General → Reminders (user decision 2026-11-12:
/// no switches on the Settings root). One switch for both notification
/// series plus a plain description of the smart schedule — until now the
/// user had no way to learn that reminders are conditional.
struct RemindersSettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.locale) private var locale

    let settings: UserSettings

    @State private var showNotificationsDenied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                toggleCard
                    .padding(.top, 8)
                GoalsSectionCaption("How it works")
                    .padding(.top, 8)
                scheduleCard
                Text("No reminder when you're on track.")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 6)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .contentColumn()
        }
        .contentMargins(.bottom, 110, for: .scrollContent)
        .background(AppBackground())
        .hidesFloatingTabBar()
        .detailNavBar(title: Text("Reminders"), onBack: { dismiss() })
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

    // MARK: - Cards

    // Same shape as every other switch row: explicit label + hidden-label
    // Toggle (the app switch style draws only the switch).
    private var toggleCard: some View {
        HStack(spacing: 12) {
            SettingsRowIcon(systemName: "bell.badge", tint: Theme.tileCoral)
            Text("Reminders")
                .font(.callout)
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
            Toggle(isOn: notificationsBinding) { Text("Reminders") }
                .labelsHidden()
                .tint(Theme.accent)
        }
        .settingsIconRowPadding()
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    private var scheduleCard: some View {
        VStack(spacing: 0) {
            scheduleRow(hour: MealReminderScheduler.afternoonHour,
                        text: "Only if nothing is logged yet")
            SettingsRowDivider()
            scheduleRow(hour: MealReminderScheduler.eveningHour,
                        text: "If you're still well under your calorie goal")
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    private func scheduleRow(hour: Int, text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(RemindersSchedule.time(hour, locale: locale))
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
                .frame(minWidth: 56, alignment: .leading)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 0)
        }
        .settingsRowPadding()
    }

    // MARK: - Switch

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
}

#Preview {
    NavigationStack {
        RemindersSettingsView(settings: UserSettings())
    }
    .modelContainer(PreviewData.container)
}

#Preview("Dark") {
    NavigationStack {
        RemindersSettingsView(settings: UserSettings())
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
