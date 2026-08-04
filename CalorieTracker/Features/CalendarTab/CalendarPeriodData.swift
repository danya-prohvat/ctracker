import Foundation
import SwiftData

/// One nutrient's mean daily intake over the visible calendar period.
struct NutrientPeriodAverage: Identifiable {
    let def: NutrientDef
    let average: Double
    let goal: Double?
    var id: String { def.id }
}

/// Everything the calendar tab derives from one visible period.
struct CalendarPeriodSnapshot {
    var kcalByDay: [String: Double] = [:]
    var stats: CalendarPeriodStats?
    var nutrientAverages: [NutrientPeriodAverage] = []
    var fullyLocked = false
}

/// Pure period-aggregation for the calendar tab: one fetch per visible period
/// and the per-day averages behind the stat cards and the nutrient history.
/// Kept out of the view so the math stays small and self-contained. Callers pass
/// entries already filtered to unlocked days (spec §9), so no aggregate ever
/// leaks data from behind the 30-day wall.
enum CalendarPeriodData {

    /// Assembles the tab's whole period state. Rings and averages cover only
    /// unlocked days, so a free user never sees aggregates from behind the
    /// 30-day wall (spec §9); locked cells render their own lock. The period
    /// counts as fully locked when even its newest day is out of the window
    /// (a period holding today or recent days always has one unlocked).
    static func snapshot(
        mode: CalendarViewMode, anchor: Date, context: ModelContext,
        settings: UserSettings?, isDayUnlocked: (String) -> Bool
    ) -> CalendarPeriodSnapshot {
        guard let interval = Calendar.current.dateInterval(of: mode.component, for: anchor) else {
            return CalendarPeriodSnapshot()
        }
        let entries = fetchEntries(in: interval, context: context)
            .filter { isDayUnlocked($0.dayKey) }
        var totals: [String: Double] = [:]
        for entry in entries {
            totals[entry.dayKey, default: 0] += entry.calories
        }
        let newestKey = DayKey.string(from: interval.end.addingTimeInterval(-1))
        return CalendarPeriodSnapshot(
            kcalByDay: totals,
            stats: macroAverages(of: entries),
            nutrientAverages: settings.map { nutrientAverages(of: entries, settings: $0) } ?? [],
            fullyLocked: !isDayUnlocked(newestKey)
        )
    }

    /// Entries whose `dayKey` falls in `interval`. "yyyy-MM-dd" strings sort
    /// lexicographically, so a string range covers a period spanning two months.
    static func fetchEntries(in interval: DateInterval, context: ModelContext) -> [DiaryEntry] {
        let startKey = DayKey.string(from: interval.start)
        // `interval.end` is the exclusive start of the next period.
        let endKey = DayKey.string(from: interval.end.addingTimeInterval(-1))
        let descriptor = FetchDescriptor<DiaryEntry>(
            predicate: #Predicate { $0.dayKey >= startKey && $0.dayKey <= endKey }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Per-day macro averages over the distinct days the entries cover (nil when
    /// empty). Sum ÷ day-count, matching the calorie rings.
    static func macroAverages(of entries: [DiaryEntry]) -> CalendarPeriodStats? {
        guard !entries.isEmpty else { return nil }
        var days: Set<String> = []
        var totalCalories = 0.0, totalProtein = 0.0, totalFat = 0.0, totalCarbs = 0.0
        for entry in entries {
            days.insert(entry.dayKey)
            totalCalories += entry.calories
            totalProtein += entry.protein
            totalFat += entry.fat
            totalCarbs += entry.carbs
        }
        let dayCount = Double(days.count)
        return CalendarPeriodStats(
            avgCalories: totalCalories / dayCount,
            avgProtein: totalProtein / dayCount,
            avgFat: totalFat / dayCount,
            avgCarbs: totalCarbs / dayCount
        )
    }

    /// Per-nutrient mean daily intake over the period, in canonical catalog order.
    /// A day feeds a nutrient's average only when that nutrient was enabled on it
    /// (`enabledNutrientIDs(on:)`) *and* some entry carries data for it — so
    /// changing the tracked set never rewrites past averages, and "no data" days
    /// are not counted as zero (matching `VitaminsMineralsSection`). The
    /// denominator is those contributing days, not the whole period.
    static func nutrientAverages(of entries: [DiaryEntry], settings: UserSettings) -> [NutrientPeriodAverage] {
        guard !entries.isEmpty else { return [] }
        let byDay = Dictionary(grouping: entries, by: { $0.dayKey })
        // nutrient id → (running sum of daily totals, count of contributing days)
        var acc: [String: (sum: Double, days: Int)] = [:]
        for (dayKey, dayEntries) in byDay {
            for id in settings.enabledNutrientIDs(on: dayKey) {
                let values = dayEntries.compactMap { $0.microValue(id) }
                guard !values.isEmpty else { continue }   // no data that day → not counted
                var running = acc[id] ?? (sum: 0, days: 0)
                running.sum += values.reduce(0, +)
                running.days += 1
                acc[id] = running
            }
        }
        return NutrientCatalog.all.compactMap { def in
            guard let bucket = acc[def.id], bucket.days > 0 else { return nil }
            return NutrientPeriodAverage(
                def: def,
                average: bucket.sum / Double(bucket.days),
                goal: settings.goal(for: def.id)
            )
        }
    }
}
