import SwiftUI

/// Frosted month card from the prototype: chevron month navigation, weekday
/// initials and a 7-column grid of `CalendarDayCell`s (padding 18/16/20,
/// radius 22). Swiping horizontally also switches months.
struct CalendarMonthCard: View {
    let displayedMonth: Date
    let kcalByDay: [String: Double]
    let calorieGoal: Double?
    let onChangeMonth: (Int) -> Void
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
                    onChangeMonth(value.translation.width < 0 ? 1 : -1)
                }
        )
    }

    // MARK: - Navigation row (prototype: 15px chevrons, 17px bold title)

    private var navRow: some View {
        HStack {
            chevronButton("chevron.backward", label: "Previous month") { onChangeMonth(-1) }
            Spacer()
            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            chevronButton("chevron.forward", label: "Next month") { onChangeMonth(1) }
        }
    }

    private func chevronButton(
        _ systemImage: String,
        label: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
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
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day grid (prototype: row gap 4, no column gap)

    private var grid: some View {
        LazyVGrid(columns: Self.columns, spacing: 4) {
            ForEach(Array(Self.gridDays(for: displayedMonth).enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(for: day)
                } else {
                    Color.clear.frame(height: 42)
                }
            }
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
            isFuture: key > todayKey
        ) {
            onTapDay(key)
        }
    }

    // MARK: - Calendar math

    /// Cells for a 7-column month grid: leading/trailing nils align day 1 with
    /// its weekday column, respecting `Calendar.current.firstWeekday`.
    private static func gridDays(for monthStart: Date) -> [Date?] {
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
        CalendarMonthCard(
            displayedMonth: Date(),
            kcalByDay: [DayKey.today: 1450],
            calorieGoal: 2200,
            onChangeMonth: { _ in },
            onTapDay: { _ in }
        )
        .padding(16)
    }
}
