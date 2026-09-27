import SwiftData
import UserNotifications

/// Startup notification permission (user decision 2026-09-27): reminders are
/// ON by default, so the system prompt is asked once at launch, right after
/// ATT, instead of waiting for the Settings toggle. Only fires while the
/// status is still `.notDetermined` — that also covers installs created when
/// the default was OFF (the toggle was never turned on there, otherwise the
/// status would be determined). A refusal flips the shared toggle off so
/// Settings reflects reality; re-enabling goes through the denied → Open
/// Settings path in `SettingsGeneralCard`.
enum NotificationStartupPrompt {
    @MainActor
    static func requestIfNeeded(in context: ModelContext) async {
        let center = UNUserNotificationCenter.current()
        guard await center.notificationSettings().authorizationStatus == .notDetermined else { return }
        let settings = UserSettings.current(in: context)
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        settings.notificationsEnabled = granted
        try? context.save()
        guard granted else { return }
        MealReminderScheduler.reschedule(in: context)
        ReengagementNotificationService.reschedule(in: context)
    }
}
