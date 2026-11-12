import SwiftUI

/// Describes the fixed smart-reminder schedule for the Settings UI. Times
/// are formatted in the app's language (env locale — `Text(date, format:)`
/// would do the same, but the row wants one interpolated sentence).
enum RemindersSchedule {
    /// One-line row subtitle: "At 14:00 and 20:00, only when needed".
    static func summary(locale: Locale) -> Text {
        Text("At \(time(MealReminderScheduler.afternoonHour, locale: locale)) and \(time(MealReminderScheduler.eveningHour, locale: locale)), only when needed")
    }

    /// "14:00" / "2:00 PM" depending on the locale.
    static func time(_ hour: Int, locale: Locale) -> String {
        let date = Calendar.current.date(
            bySettingHour: hour, minute: 0, second: 0, of: Date()
        ) ?? Date()
        return date.formatted(
            Date.FormatStyle(date: .omitted, time: .shortened).locale(locale)
        )
    }
}
