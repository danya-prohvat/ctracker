import SwiftUI

/// Time scale the calendar grid shows (user request 2026-07-09): a single
/// week strip or the full month grid. Chosen by the segmented control and
/// drives the grid layout, the chevron/swipe step, and the fetched period.
enum CalendarViewMode: CaseIterable {
    case week, month

    var label: LocalizedStringKey {
        switch self {
        case .week: "Week"
        case .month: "Month"
        }
    }

    /// Calendar component this mode spans — used both for the period fetch and
    /// for stepping forward/back one unit.
    var component: Calendar.Component {
        switch self {
        case .week: .weekOfYear
        case .month: .month
        }
    }

    /// Localized "Jul 6 – 12" range for the week starting at `weekStart`.
    /// `locale` is the view's environment locale — a bare `.formatted()`
    /// follows the launch-frozen process locale and kept the month name in
    /// the previous language after an in-app language switch.
    static func weekRangeLabel(_ weekStart: Date, locale: Locale) -> String {
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return (weekStart..<max(end, weekStart.addingTimeInterval(1)))
            .formatted(Date.IntervalFormatStyle(date: .abbreviated, time: .omitted, locale: locale))
    }
}
