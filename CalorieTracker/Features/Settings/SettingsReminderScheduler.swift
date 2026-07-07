import Foundation
import UserNotifications

/// Schedules the repeating meal-reminder local notifications configured in
/// Settings. Identifiers are namespaced so rescheduling never touches other
/// notifications the app may post later.
enum SettingsReminderScheduler {
    private static let idPrefix = "settings.mealReminder."

    /// Ask for notification permission. The system prompts only on the first
    /// call; later calls report the already-granted/denied status.
    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Replace all pending meal reminders with one repeating calendar trigger
    /// per configured time (minutes from local midnight).
    static func reschedule(minutesList: [Int]) {
        let center = UNUserNotificationCenter.current()
        let newIDs = Set(minutesList.map { idPrefix + String($0) })

        center.getPendingNotificationRequests { requests in
            let stale = requests.map(\.identifier)
                .filter { $0.hasPrefix(idPrefix) && !newIDs.contains($0) }
            center.removePendingNotificationRequests(withIdentifiers: stale)

            for minutes in Set(minutesList) {
                var components = DateComponents()
                components.hour = minutes / 60
                components.minute = minutes % 60
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

                let content = UNMutableNotificationContent()
                content.title = String(localized: "Meal reminder")
                content.body = String(localized: "Don't forget to log your meal")
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: idPrefix + String(minutes),
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }
        }
    }

    /// Cancel every pending meal reminder (toggle off / delete all data).
    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
