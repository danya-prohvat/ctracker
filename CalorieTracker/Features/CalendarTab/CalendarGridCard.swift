import SwiftUI

/// The calendar card (prototype: padding 18/16/20, radius 22): chevron/swipe
/// navigation over a 7-column grid of `CalendarDayCell`s. In `.month` mode it's
/// a 7×N grid with leading blanks; in `.week` mode it's the seven days of one
/// week. The mode and visible period are owned by the parent.
struct CalendarGridCard: View {
    let mode: CalendarViewMode
    /// Start of the visible period (month-start or week-start).
    let anchor: Date
    let kcalByDay: [String: Double]
    let calorieGoal: Double?
    /// Whether a day falls outside the free-tier history window (spec §9).
    let isDayLocked: (String) -> Bool
    let onStep: (Int) -> Void
    let onTapDay: (String) -> Void

    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            navRow
                .padding(.horizontal, 6)
                .padding(.bottom, 14)
            weekdayRow
                .padding(.bottom, 8)
            grid
        }
        .padding(.top, 18)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .glassCard(cornerRadius: 22)
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height),
                          abs(value.translation.width) > 40 else { return }
                    onStep(value.translation.width < 0 ? 1 : -1)
                }
        )
    }

    // MARK: - Navigation row (prototype: 15px chevrons, 17px bold title)

    private var navRow: some View {
        HStack {
            chevronButton("chevron.backward", label: prevLabel) { onStep(-1) }
            Spacer()
            title
                .font(.body.bold())
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            chevronButton("chevron.forward", label: nextLabel) { onStep(1) }
        }
    }

    private var title: Text {
        switch mode {
        case .month: Text(anchor, format: .dateTime.month(.wide).year())
        case .week: Text(verbatim: CalendarViewMode.weekRangeLabel(anchor))
        }
    }

    private var prevLabel: LocalizedStringKey { mode == .week ? "Previous week" : "Previous month" }
    private var nextLabel: LocalizedStringKey { mode == .week ? "Next week" : "Next month" }

    private func chevronButton(
        _ systemImage: String,
        label: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.chevron)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    // MARK: - Weekday initials (prototype: 11px semibold)

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            // Symbols can repeat (e.g. "T", "T" in English), so identify by column.
            ForEach(Array(Self.weekdaySymbols().enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day grid (prototype: row gap 4, no column gap)

    private var grid: some View {
        LazyVGrid(columns: Self.columns, spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(for: day)
                } else {
                    Color.clear.frame(height: 42)
                }
            }
        }
    }

    private var days: [Date?] {
        switch mode {
        case .month: Self.monthGridDays(for: anchor)
        case .week: Self.weekDays(for: anchor)
        }
    }

    private func dayCell(for day: Date) -> some View {
        let key = DayKey.string(from: day)
        let todayKey = DayKey.today
        return CalendarDayCell(
            date: day,
            kcal: kcalByDay[key],
            calorieGoal: calorieGoal,
            isToday: key == todayKey,
            isFuture: key > todayKey,
            isLocked: isDayLocked(key)
        ) {
            onTapDay(key)
        }
    }

    // MARK: - Calendar math

    /// The seven days of the week starting at `weekStart`.
    private static func weekDays(for weekStart: Date) -> [Date?] {
        let calendar = Calendar.current
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    /// Cells for a 7-column month grid: leading/trailing nils align day 1 with
    /// its weekday column, respecting `Calendar.current.firstWeekday`.
    private static func monthGridDays(for monthStart: Date) -> [Date?] {
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
    private static func weekdaySymbols() -> [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        guard symbols.indices.contains(first) else { return symbols }
        return Array(symbols[first...]) + Array(symbols[..<first])
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 16) {
            CalendarGridCard(
                mode: .month, anchor: Date(),
                kcalByDay: [DayKey.today: 1450], calorieGoal: 2200,
                isDayLocked: { _ in false },
                onStep: { _ in }, onTapDay: { _ in }
            )
            CalendarGridCard(
                mode: .week, anchor: Date(),
                kcalByDay: [DayKey.today: 1450], calorieGoal: 2200,
                isDayLocked: { _ in false },
                onStep: { _ in }, onTapDay: { _ in }
            )
        }
        .padding(16)
    }
}
