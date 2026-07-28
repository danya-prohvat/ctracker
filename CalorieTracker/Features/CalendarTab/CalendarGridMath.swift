import Foundation

/// Pure calendar math behind `CalendarGridCard`: day cells for the week and
/// month grids plus the localized weekday header symbols.
enum CalendarGridMath {
    /// The seven days of the week starting at `weekStart`.
    static func weekDays(for weekStart: Date) -> [Date?] {
        let calendar = Calendar.current
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    /// Cells for a 7-column month grid: leading/trailing nils align day 1 with
    /// its weekday column, respecting `Calendar.current.firstWeekday`.
    static func monthGridDays(for monthStart: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: monthStart),
              let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count
        else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        var cells = [Date?](repeating: nil, count: leading)
        for offset in 0..<dayCount {
            if let day = calendar.date(byAdding: .day, value: offset, to: interval.start) {
                cells.append(day)
            }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    /// Localized single-letter weekday symbols rotated to the user's first weekday.
    static func weekdaySymbols() -> [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        guard symbols.indices.contains(first) else { return symbols }
        return Array(symbols[first...]) + Array(symbols[..<first])
    }
}
