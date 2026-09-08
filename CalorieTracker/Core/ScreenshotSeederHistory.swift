#if DEBUG
import Foundation
import SwiftData

/// Calendar-history half of the screenshot seeder (see ScreenshotSeeder.swift):
/// fills the weeks before today so the month grid is a full green/amber mix.
extension ScreenshotSeeder {
    // MARK: - Calendar history (month grid frame)

    /// Ring mix for the month grid: amber and missed days pinned per month
    /// number (7 = July, 8 = August…), everything else green. Green ratios
    /// cycle inside the 80–105% band so rings vary but stay green.
    static let amberDays: [Int: Set<Int>] = [7: [5, 14, 26], 8: [8]]
    static let missedDays: [Int: Set<Int>] = [7: [12, 21], 8: [13]]
    static let greenRatios: [Double] = [0.86, 0.93, 0.99, 0.89, 1.02, 0.84, 0.96]
    static let amberRatios: [Double] = [1.12, 1.18, 1.24]

    /// Seeds the ~7 weeks before today, so the previous month is a full grid
    /// (mostly green rings, 3 amber, 2 gaps) and the current month matches.
    @MainActor
    static func seedHistory(_ context: ModelContext, goal: Double) {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        for offset in 1...52 {
            guard let dayStart = cal.date(byAdding: .day, value: -offset, to: todayStart) else { continue }
            let comps = cal.dateComponents([.month, .day], from: dayStart)
            guard let month = comps.month, let day = comps.day else { continue }
            if missedDays[month]?.contains(day) == true { continue }
            let ratio = amberDays[month]?.contains(day) == true
                ? amberRatios[day % amberRatios.count]
                : greenRatios[day % greenRatios.count]
            // Five rotating foods, scaled so the day lands on ratio × goal.
            let chosen = (0..<5).map { items[(offset + $0) % items.count] }
            let base = chosen.reduce(0) { $0 + $1.calories * $1.quantity / 100 }
            let scale = ratio * goal / base
            for (slot, item) in chosen.enumerated() {
                let date = cal.date(bySettingHour: 8 + slot * 3, minute: 10,
                                    second: 0, of: dayStart) ?? dayStart
                context.insert(DiaryEntry(
                    loggedAt: date, dayKey: DayKey.string(from: dayStart),
                    productName: localizedName(item), basis: .per100g,
                    quantity: (item.quantity * scale * 10).rounded() / 10,
                    per100Calories: item.calories, per100Protein: item.protein,
                    per100Fat: item.fat, per100Carbs: item.carbs,
                    per100Micros: item.micros))
            }
        }
    }
}
#endif
