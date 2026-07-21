import Foundation
import StoreKit
import SwiftData
import UIKit

/// Asks iOS for the App Store rating dialog (`AppStore.requestReview`) on two
/// independent triggers (user decision 2026-07-21):
/// 1. App open on day 2/5/14/21/31/62/93 since first launch, if the store
///    already holds at least one product or diary entry.
/// 2. Today lands in the green zone (75–105% of the calorie goal) on day
///    1/3/7/14/21/31/62/93 since first launch.
/// Day 1 = the first-launch day. Each trigger-day fires at most once; iOS
/// itself decides whether the dialog actually appears (max 3 per year), so
/// this only *requests* — repeat requests are ignored by the system. State
/// lives in UserDefaults: review prompts are a per-device concern and must
/// not sync via CloudKit.
@MainActor
enum ReviewPromptService {
    private static let openDays: Set<Int> = [2, 5, 14, 21, 31, 62, 93]
    private static let greenDays: Set<Int> = [1, 3, 7, 14, 21, 31, 62, 93]
    private static let greenZone = 0.75...1.05

    private static let firstLaunchKey = "review.firstLaunchAt"
    private static let consumedKey = "review.consumedTriggers"

    /// Both triggers — call on every scene activation.
    static func checkOnActivation(in context: ModelContext) {
        checkAppOpen(in: context)
        checkGreenZone(in: context)
    }

    /// Green-zone trigger only — call after a diary mutation for today.
    /// Deletes are not hooked on purpose: prompting right after a removal
    /// feels off, and the next activation re-checks the day anyway.
    static func checkGreenZone(in context: ModelContext) {
        let day = dayNumber
        guard greenDays.contains(day), !isConsumed("green.\(day)") else { return }
        guard let goal = UserSettings.current(in: context).calorieGoal, goal > 0 else { return }
        let today = DayKey.today
        let descriptor = FetchDescriptor<DiaryEntry>(predicate: #Predicate { $0.dayKey == today })
        let eaten = ((try? context.fetch(descriptor)) ?? []).reduce(0) { $0 + $1.calories }
        guard greenZone.contains(eaten / goal) else { return }
        consume("green.\(day)")
        requestReview()
    }

    private static func checkAppOpen(in context: ModelContext) {
        let day = dayNumber
        guard openDays.contains(day), !isConsumed("open.\(day)"), hasAnyData(in: context) else { return }
        consume("open.\(day)")
        requestReview()
    }

    private static func hasAnyData(in context: ModelContext) -> Bool {
        var products = FetchDescriptor<Product>()
        products.fetchLimit = 1
        if ((try? context.fetchCount(products)) ?? 0) > 0 { return true }
        var entries = FetchDescriptor<DiaryEntry>()
        entries.fetchLimit = 1
        return ((try? context.fetchCount(entries)) ?? 0) > 0
    }

    /// 1-based day since first launch (day 1 = the first-launch day). Seeds the
    /// stored date on first access, so installs that predate this feature start
    /// counting from this build's first run.
    private static var dayNumber: Int {
        let defaults = UserDefaults.standard
        var first = Date(timeIntervalSince1970: defaults.double(forKey: firstLaunchKey))
        if first.timeIntervalSince1970 <= 0 {
            first = Date()
            defaults.set(first.timeIntervalSince1970, forKey: firstLaunchKey)
        }
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: first),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0
        return days + 1
    }

    private static func isConsumed(_ trigger: String) -> Bool {
        (UserDefaults.standard.stringArray(forKey: consumedKey) ?? []).contains(trigger)
    }

    private static func consume(_ trigger: String) {
        var all = UserDefaults.standard.stringArray(forKey: consumedKey) ?? []
        all.append(trigger)
        UserDefaults.standard.set(all, forKey: consumedKey)
    }

    /// Requests after a beat so a dismissing sheet (the log flow) settles first.
    private static func requestReview() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            guard let scene else { return }
            AppStore.requestReview(in: scene)
        }
    }
}

#if DEBUG
extension ReviewPromptService {
    static var debugDayNumber: Int { dayNumber }

    /// Moves the stored first launch one day back → `dayNumber` advances by 1.
    static func debugAdvanceDay() {
        let defaults = UserDefaults.standard
        let stored = defaults.double(forKey: firstLaunchKey)
        let base = stored > 0 ? stored : Date().timeIntervalSince1970
        defaults.set(base - 86_400, forKey: firstLaunchKey)
    }

    static func debugReset() {
        UserDefaults.standard.removeObject(forKey: consumedKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: firstLaunchKey)
    }
}
#endif
