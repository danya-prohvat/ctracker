import Foundation

/// One point where the user's tracked-nutrient set changed, frozen to the local
/// day it happened. The set effective for any day is the latest change on or
/// before that day — so a past day shows what was tracked *then*, and toggling a
/// nutrient today never rewrites history (spec §2.1). Codable so SwiftData stores
/// it inline on `UserSettings`; CloudKit-safe (persisted as a data blob, no
/// unique constraints, every field defaulted).
struct NutrientTrackingChange: Codable, Hashable {
    /// Local day the set took effect, "yyyy-MM-dd" (`DayKey`), or `DayKey.beginning`
    /// for the initial baseline that covers every prior day.
    var dayKey: String = DayKey.beginning
    /// Enabled nutrient ids as of this change.
    var enabledNutrients: [String] = []
}

extension UserSettings {
    /// Enabled nutrient ids effective on `dayKey`: the most recent change on or
    /// before it. Falls back to the live set when the log has no entry that early
    /// (legacy days logged before the log existed), preserving prior behavior.
    func enabledNutrientIDs(on dayKey: String) -> [String] {
        let latest = nutrientTrackingLog
            .filter { $0.dayKey <= dayKey }
            .max { $0.dayKey < $1.dayKey }
        return latest?.enabledNutrients ?? enabledNutrients
    }

    /// Enabled nutrient defs effective on `dayKey`, in canonical catalog order.
    func enabledNutrientDefs(on dayKey: String) -> [NutrientDef] {
        let ids = Set(enabledNutrientIDs(on: dayKey))
        return NutrientCatalog.all.filter { ids.contains($0.id) }
    }

    /// Seed the initial baseline (the current set, effective from before any real
    /// day) the first time the log is written, so days prior to the first change
    /// keep the set they actually had. Idempotent — call *before* mutating the set.
    func ensureNutrientTrackingBaseline() {
        guard nutrientTrackingLog.isEmpty else { return }
        nutrientTrackingLog = [
            NutrientTrackingChange(dayKey: DayKey.beginning, enabledNutrients: enabledNutrients)
        ]
    }

    /// Freeze the current `enabledNutrients` as the set effective from `dayKey`
    /// (default today) onward. Replaces an existing same-day entry so several
    /// toggles in one day collapse to that day's final state; never touches earlier
    /// days, so history stays immutable. Call *after* mutating the set.
    func recordNutrientTrackingChange(on dayKey: String = DayKey.today) {
        var log = nutrientTrackingLog.filter { $0.dayKey != dayKey }
        log.append(NutrientTrackingChange(dayKey: dayKey, enabledNutrients: enabledNutrients))
        nutrientTrackingLog = log.sorted { $0.dayKey < $1.dayKey }
    }
}
