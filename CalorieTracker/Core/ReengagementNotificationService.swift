import Foundation
import SwiftData
import UserNotifications

/// Schedules the re-engagement series (user decision 2026-07-19): six local
/// notifications at 12:00 on days 2, 4, 7, 14, 21 and 31 after the last app
/// open. Day 14 slides off Sat/Sun to the next Monday 9:00.
///
/// The series is cancelled and replanned from "now" on every activation
/// (RootView), so a notification only ever fires if the app really stayed
/// unopened that long. On/off follows the single Reminders toggle
/// (`UserSettings.notificationsEnabled`, user decision 2026-07-21). Never
/// prompts for permission — plans only when the status is already
/// authorized/provisional (the Reminders toggle owns the permission flow);
/// otherwise it does nothing, silently.
enum ReengagementNotificationService {
    private static let idPrefix = "reengagement."

    /// Day offsets with their String Catalog body keys (Localizable.xcstrings).
    private static let steps: [(day: Int, bodyKey: String.LocalizationValue)] = [
        (2, "reengagement_day2"),
        (4, "reengagement_day4"),
        (7, "reengagement_day7"),
        (14, "reengagement_day14"),
        (21, "reengagement_day21"),
        (31, "reengagement_day31"),
    ]

    private static let fireHour = 12
    private static let weekendShiftHour = 9
    private static let weekendShiftDay = 14

    /// Stable identifiers ("reengagement.day2" … "reengagement.day31") —
    /// cancellation by exact id never touches other notification types.
    private static var allIDs: [String] { steps.map { idPrefix + "day\($0.day)" } }

    /// Cancel and replan the full series from now. Call on every activation.
    @MainActor
    static func reschedule(in context: ModelContext) {
        let settings = UserSettings.current(in: context)
        guard settings.notificationsEnabled else {
            cancelAll()
            return
        }
        let bundle = AppLanguage.bundle(for: settings.languageCode)
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { permission in
            guard permission.authorizationStatus == .authorized
                || permission.authorizationStatus == .provisional else { return }
            center.removePendingNotificationRequests(withIdentifiers: allIDs)
            requests(from: Date(), bundle: bundle).forEach { center.add($0) }
        }
    }

    /// Cancel the whole series (toggle off / delete all data).
    static func cancelAll() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: allIDs)
    }

    // MARK: - Planning

    private static func requests(from now: Date, bundle: Bundle) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        return steps.compactMap { step in
            guard let fire = fireDate(day: step.day, from: now, calendar: calendar) else {
                return nil
            }
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fire
            )
            return request(
                day: step.day,
                bodyKey: step.bodyKey,
                bundle: bundle,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
        }
    }

    /// 12:00 on `day` days from now; day 14 slides off Sat/Sun to Monday 9:00.
    private static func fireDate(day: Int, from now: Date, calendar: Calendar) -> Date? {
        guard var target = calendar.date(byAdding: .day, value: day, to: now) else { return nil }
        var hour = fireHour
        if day == weekendShiftDay {
            // Gregorian weekday numbering: 1 = Sunday, 7 = Saturday.
            let weekday = calendar.component(.weekday, from: target)
            let shift = weekday == 7 ? 2 : (weekday == 1 ? 1 : 0)
            if shift > 0 {
                guard let monday = calendar.date(byAdding: .day, value: shift, to: target) else {
                    return nil
                }
                target = monday
                hour = weekendShiftHour
            }
        }
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: target)
    }

    private static func request(
        day: Int, bodyKey: String.LocalizationValue, bundle: Bundle,
        trigger: UNNotificationTrigger
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        // Title stays empty on purpose — iOS shows the app name instead.
        content.body = String(localized: bodyKey, bundle: bundle)
        content.sound = .default
        return UNNotificationRequest(
            identifier: idPrefix + "day\(day)",
            content: content,
            trigger: trigger
        )
    }

    #if DEBUG
    /// Manual-testing variant: same series, texts and identifiers, but
    /// "day N" fires N minutes from now instead of N days.
    static func scheduleTestSeriesMinutes(languageCode: String?) {
        let bundle = AppLanguage.bundle(for: languageCode)
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { permission in
            guard permission.authorizationStatus == .authorized
                || permission.authorizationStatus == .provisional else { return }
            center.removePendingNotificationRequests(withIdentifiers: allIDs)
            for step in steps {
                center.add(request(
                    day: step.day,
                    bodyKey: step.bodyKey,
                    bundle: bundle,
                    trigger: UNTimeIntervalNotificationTrigger(
                        timeInterval: TimeInterval(step.day * 60), repeats: false
                    )
                ))
            }
        }
    }
    #endif
}
