import SwiftUI

/// The calendar card (prototype: padding 18/16/20, radius 22): chevron/swipe
/// navigation over a 7-column grid of `CalendarDayCell`s. In `.month` mode it's
/// a 7×N grid with leading blanks; in `.week` mode it's the seven days of one
/// week. The mode and visible period are owned by the parent.
struct CalendarGridCard: View {
    let mode: CalendarViewMode
    /// Start of the visible period (month-start or week-start).
    let anchor: Date
    /// Last period step (-1 back / +1 forward / 0 none) — picks the direction
    /// the day grid slides in from; 0 falls back to a plain crossfade.
    let stepDirection: Int
    /// "Today" from the parent's day-change-aware state — never computed at
    /// render time, or the marker (and the disabled "future" cells) would
    /// freeze on yesterday past midnight.
    let todayKey: String
    let kcalByDay: [String: Double]
    let calorieGoal: Double?
    /// Whether a day falls outside the free-tier history window (spec §9).
    let isDayLocked: (String) -> Bool
    let onStep: (Int) -> Void
    let onTapDay: (String) -> Void

    @Environment(\.layoutDirection) private var layoutDirection

    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            navRow
                .padding(.horizontal, 6)
                .padding(.bottom, 14)
            weekdayRow
                .padding(.bottom, 8)
            // ZStack overlays old and new grids during the transition (no
            // vertical layout jump); clipped keeps the slide inside the card.
            ZStack {
                grid
                    .id(anchor)
                    .transition(gridTransition)
            }
            .clipped()
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
                    // Drag translation is physical; flip so a swipe toward the
                    // start of reading order always means "next" under RTL too.
                    let step = value.translation.width < 0 ? 1 : -1
                    onStep(layoutDirection == .rightToLeft ? -step : step)
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
            ForEach(Array(CalendarGridMath.weekdaySymbols().enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day grid (prototype: row gap 4, no column gap)

    private var gridTransition: AnyTransition {
        if stepDirection > 0 { return .push(from: .trailing) }
        if stepDirection < 0 { return .push(from: .leading) }
        return .opacity
    }

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
        case .month: CalendarGridMath.monthGridDays(for: anchor)
        case .week: CalendarGridMath.weekDays(for: anchor)
        }
    }

    private func dayCell(for day: Date) -> some View {
        let key = DayKey.string(from: day)
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

}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 16) {
            CalendarGridCard(
                mode: .month, anchor: Date(), stepDirection: 0,
                todayKey: DayKey.today,
                kcalByDay: [DayKey.today: 1450], calorieGoal: 2200,
                isDayLocked: { _ in false },
                onStep: { _ in }, onTapDay: { _ in }
            )
            CalendarGridCard(
                mode: .week, anchor: Date(), stepDirection: 0,
                todayKey: DayKey.today,
                kcalByDay: [DayKey.today: 1450], calorieGoal: 2200,
                isDayLocked: { _ in false },
                onStep: { _ in }, onTapDay: { _ in }
            )
        }
        .padding(16)
    }
}
