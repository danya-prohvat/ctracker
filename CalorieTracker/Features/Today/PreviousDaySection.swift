import SwiftUI
import SwiftData

/// "Last logged day" on the Today root (user decision 2026-11-11): the most
/// recent past day that has diary entries — yesterday, two days ago or a
/// plain date — as a compact card that opens that day's detail. Exactly one
/// past day, never more. Nothing is rendered while no past day exists.
struct PreviousDaySection: View {
    @Environment(\.locale) private var locale

    let todayKey: String
    let settings: UserSettings?
    let unitSystem: UnitSystem

    /// The newest entry before today; its `dayKey` names the day to show.
    /// `yyyy-MM-dd` keys sort chronologically as plain strings.
    @Query private var latest: [DiaryEntry]

    init(todayKey: String, settings: UserSettings?, unitSystem: UnitSystem) {
        self.todayKey = todayKey
        self.settings = settings
        self.unitSystem = unitSystem
        let key = todayKey
        var descriptor = FetchDescriptor<DiaryEntry>(
            predicate: #Predicate<DiaryEntry> { $0.dayKey < key },
            sortBy: [SortDescriptor(\.dayKey, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        _latest = Query(descriptor)
    }

    private var isUnlocked: Bool {
        guard let key = latest.first?.dayKey, let settings else { return true }
        return PremiumGate.isDayUnlocked(dayKey: key, settings: settings)
    }

    var body: some View {
        if let key = latest.first?.dayKey {
            PreviousDayCard(
                dayKey: key,
                title: Self.title(for: key, todayKey: todayKey, locale: locale),
                unitSystem: unitSystem,
                isUnlocked: isUnlocked
            )
        }
    }

    /// "Yesterday" / "2 days ago" for the two nearest days, otherwise the
    /// date ("4 November", with the year once it differs from today's).
    static func title(for dayKey: String, todayKey: String, locale: Locale) -> String {
        guard let day = DayKey.date(from: dayKey), let today = DayKey.date(from: todayKey) else {
            return dayKey
        }
        let calendar = Calendar.current
        let daysAgo = calendar.dateComponents([.day], from: day, to: today).day ?? 0
        if daysAgo <= 2 {
            let relative = day.formatted(
                Date.RelativeFormatStyle(presentation: .named, unitsStyle: .wide,
                                         locale: locale, calendar: calendar)
            )
            return relative.prefix(1).uppercased(with: locale) + relative.dropFirst()
        }
        let sameYear = calendar.isDate(day, equalTo: today, toGranularity: .year)
        return sameYear
            ? day.formatted(.dateTime.month(.wide).day().locale(locale))
            : day.formatted(.dateTime.year().month(.wide).day().locale(locale))
    }
}
