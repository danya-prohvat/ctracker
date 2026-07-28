import Foundation
import SwiftData
import WidgetKit

/// Snapshot of today's totals shared with the home-screen widget through the
/// App Group defaults — the widget has no access to the SwiftData store, so
/// this JSON blob is the entire contract (mirrored in the widget target).
struct WidgetDaySnapshot: Codable {
    var dayKey: String = ""
    var consumedKcal: Double = 0
    var calorieGoal: Double?
    var updatedAt: Date = .distantPast
}

/// The app side of the widget pipeline: recomputes today's totals and pushes
/// them to the shared container. Hooked into `DiaryLogger.log` and scene-phase
/// changes in `RootView`, so the widget is fresh whenever the user leaves.
enum WidgetBridge {
    /// Must match the App Group added to BOTH targets in Signing & Capabilities.
    static let appGroupID = "group.com.prxfitness.calorietracker"
    static let snapshotKey = "widget.daySnapshot"

    /// Silent no-op until the App Group capability is configured — the app
    /// must keep working without the widget target.
    @MainActor
    static func refresh(in context: ModelContext) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        let key = DayKey.today
        let descriptor = FetchDescriptor<DiaryEntry>(
            predicate: #Predicate { $0.dayKey == key }
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        let settings = UserSettings.current(in: context)

        var snapshot = WidgetDaySnapshot()
        snapshot.dayKey = key
        snapshot.consumedKcal = entries.reduce(0) { $0 + $1.calories }
        snapshot.calorieGoal = settings.calorieGoal
        snapshot.updatedAt = Date()

        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
