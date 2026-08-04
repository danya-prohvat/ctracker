import Foundation
import SwiftData
import UserNotifications

/// Plans the two daily "smart" meal reminders (user decision 2026-07-19):
/// 14:00 — only when nothing is logged for that day yet; 20:00 — nothing
/// logged → nudge to log, logged under 80% of the calorie goal → says how
/// many kcal are left, at/over 80% → stays silent.
///
/// Local notifications can't evaluate conditions at delivery time, so the
/// next 7 days are planned ahead from the current diary state and fully
/// replanned on every scene-phase change. Logging only happens in-app, so
/// the schedule is always refreshed before it could become stale.
enum MealReminderScheduler {
    private static let idPrefix = "smartReminder."
    /// Pre-2026-07-19 user-configured meal reminders — cleaned up on every pass.
    private static let legacyIDPrefix = "settings.mealReminder."

    private static let afternoonHour = 14
    private static let eveningHour = 20
    private static let daysPlanned = 7
    private static let goalFraction = 0.8

    /// Ask for notification permission. The system prompts only on the first
    /// call; later calls report the already-granted/denied status.
    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async { completion(granted) }
            }
    }

    /// Current system permission, reported on the main queue. `.denied` means
    /// `requestAuthorization` would fail silently without showing a prompt —
    /// the caller should point the user to iOS Settings instead.
    static func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    /// Replace the whole planned window based on the current diary state.
    @MainActor
    static func reschedule(in context: ModelContext) {
        let settings = UserSettings.current(in: context)
        guard settings.notificationsEnabled else {
            cancelAll()
            return
        }
        let requests = plan(
            todayCalories: todayCalories(in: context),
            calorieGoal: settings.calorieGoal,
            now: Date(),
            bundle: AppLanguage.bundle(for: settings.languageCode)
        )
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let stale = pending.map(\.identifier)
                .filter { $0.hasPrefix(idPrefix) || $0.hasPrefix(legacyIDPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: stale)
            requests.forEach { center.add($0) }
        }
    }

    /// Cancel every planned reminder (toggle off / delete all data).
    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let ids = pending.map(\.identifier)
                .filter { $0.hasPrefix(idPrefix) || $0.hasPrefix(legacyIDPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Planning

    /// `todayCalories` nil = nothing logged today. Future days always plan the
    /// "nothing logged" variants — logging requires opening the app, which
    /// triggers a full replan anyway.
    private static func plan(
        todayCalories: Double?, calorieGoal: Double?, now: Date, bundle: Bundle
    ) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        var requests: [UNNotificationRequest] = []

        for offset in 0..<daysPlanned {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let key = DayKey.string(from: day)
            let logged = offset == 0 ? todayCalories : nil

            if logged == nil,
               let fire = fireDate(hour: afternoonHour, of: day, calendar: calendar),
               fire > now {
                requests.append(request(
                    id: idPrefix + "afternoon." + key,
                    fire: fire,
                    calendar: calendar,
                    body: String(
                        localized: "You haven't logged anything today yet. Add your first meal!",
                        bundle: bundle
                    ),
                    bundle: bundle
                ))
            }

            if let fire = fireDate(hour: eveningHour, of: day, calendar: calendar),
               fire > now,
               let body = eveningBody(logged: logged, goal: calorieGoal, bundle: bundle) {
                requests.append(request(
                    id: idPrefix + "evening." + key,
                    fire: fire,
                    calendar: calendar,
                    body: body,
                    bundle: bundle
                ))
            }
        }
        return requests
    }

    /// Nil = stay silent (at/over 80% of the goal, or logged with no goal set).
    private static func eveningBody(logged: Double?, goal: Double?, bundle: Bundle) -> String? {
        guard let logged else {
            return String(localized: "Don't forget to log your meals for today.", bundle: bundle)
        }
        guard let goal, goal > 0, logged < goal * goalFraction else { return nil }
        let left = Format.kcal(goal - logged)
        return String(
            localized: "You still have \(left) kcal left today. Log your dinner!",
            bundle: bundle
        )
    }

    private static func fireDate(hour: Int, of day: Date, calendar: Calendar) -> Date? {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)
    }

    private static func request(
        id: String, fire: Date, calendar: Calendar, body: String, bundle: Bundle
    ) -> UNNotificationRequest {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Meal reminder", bundle: bundle)
        content.body = body
        content.sound = .default
        return UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
    }

    @MainActor
    private static func todayCalories(in context: ModelContext) -> Double? {
        let key = DayKey.today
        let descriptor = FetchDescriptor<DiaryEntry>(predicate: #Predicate { $0.dayKey == key })
        guard let entries = try? context.fetch(descriptor), !entries.isEmpty else { return nil }
        return entries.reduce(0) { $0 + $1.calories }
    }
}
