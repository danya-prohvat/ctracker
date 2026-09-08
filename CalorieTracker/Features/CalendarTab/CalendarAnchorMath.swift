import Foundation

/// Pure anchor math for the calendar grid: period starts, the initial
/// (DEBUG-shiftable) anchor, and re-anchoring on a week↔month scale switch.
/// Extracted from `CalendarTabView` (200-line rule).
enum CalendarAnchorMath {
    /// Start of the calendar period (`.weekOfYear` or `.month`) containing `date`.
    static func periodStart(of component: Calendar.Component, for date: Date) -> Date {
        Calendar.current.dateInterval(of: component, for: date)?.start ?? date
    }

    /// Anchor for the first render: the current month — or, in DEBUG, N months
    /// back via the `-calendarMonthsBack N` screenshot launch argument (the
    /// current month is too empty early on). Positive on purpose: a negative
    /// launch-arg value would parse as the next flag.
    static func initialAnchor() -> Date {
        var date = Date()
        #if DEBUG
        let back = UserDefaults.standard.integer(forKey: "calendarMonthsBack")
        if back > 0, let shifted = Calendar.current.date(
            byAdding: .month, value: -back, to: date) {
            date = shifted
        }
        #endif
        return periodStart(of: .month, for: date)
    }

    /// New anchor after a week↔month scale switch. When the period the user
    /// was looking at contains today, the new scale re-anchors on today so the
    /// today cell (and its ring) stays visible — deriving month→week from the
    /// old anchor always landed on the week of the 1st, hiding today (fix
    /// 2026-09-07). Otherwise it stays near where they were, derived from the
    /// displayed period.
    static func switchAnchor(
        from oldMode: CalendarViewMode, to newMode: CalendarViewMode,
        anchor: Date, todayKey: String
    ) -> Date {
        var base = anchor
        // Containment via day keys: `dateInterval` ends at the next period's
        // midnight, so a plain `contains(today)` would match one day too many.
        if let period = Calendar.current.dateInterval(of: oldMode.component, for: anchor),
           DayKey.string(from: period.start) <= todayKey,
           todayKey < DayKey.string(from: period.end),
           let today = DayKey.date(from: todayKey) {
            base = today
        }
        return periodStart(of: newMode.component, for: base)
    }
}
