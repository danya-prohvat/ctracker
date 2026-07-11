import SwiftUI

/// One month-grid day (prototype: 42pt-high cell, 40pt circle area). A day
/// with logged data draws a 40×40 progress ring (day kcal vs. target) behind a
/// 14pt day number; empty and future days show only a muted number.
///
/// The ring color reflects how the day compares to the calorie target
/// (`CalendarRingState`): green on target, muted gray when under (or with no
/// target), amber when over. The fill is the actual percentage, except an
/// over day is fully filled. See `CalendarRingLegend` for the key.
///
/// Today is marked with a soft brand-tinted disc behind a bold green number,
/// wrapped in a progress ring that fills with the calories logged so far. The
/// ring is scored live by the same `CalendarRingState` logic as past days —
/// neutral under, green on target, amber over — so it reflects how the day is
/// going. The soft disc and green number keep it identifiable as the current
/// day.
struct CalendarDayCell: View {
    let date: Date
    /// Total kcal logged that day; `nil` when nothing was logged.
    let kcal: Double?
    let calorieGoal: Double?
    let isToday: Bool
    let isFuture: Bool
    let onTap: () -> Void

    /// Ring track from the prototype day cells (#EEEEF0).
    private static let ringTrack = Color(hex: 0xEEEEF0)

    private var hasData: Bool { kcal != nil }

    private var ringState: CalendarRingState {
        CalendarRingState(consumed: kcal ?? 0, target: calorieGoal)
    }

    /// Actual percentage of target (capped at 100% visually). With no target,
    /// a full neutral ring marks the day as logged without any judgment.
    private var progress: Double {
        guard let kcal else { return 0 }
        guard let goal = calorieGoal, goal > 0 else { return 1 }
        return min(1, kcal / goal)
    }

    /// Today's number is brand green on its soft tinted disc; other days use
    /// primary (with data) or muted (empty) — never a scored ring color.
    private var numberColor: Color {
        if isToday { return Theme.accentDeep }
        return hasData ? Theme.textPrimary : Theme.calendarDayMuted
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isToday {
                    // Soft brand-tinted disc marks the current day behind its
                    // ring and bold green number.
                    Circle()
                        .fill(Theme.accentSoft)
                        .padding(4)
                }
                if isToday || hasData {
                    // Progress ring: fill = calories vs target, colored live by
                    // CalendarRingState (neutral under, green on target, amber
                    // over). Today is scored the same way as past days as it
                    // fills through the day.
                    ProgressRing(
                        progress: progress,
                        lineWidth: 4,
                        color: ringState.color,
                        trackColor: Self.ringTrack
                    )
                }
                Text(date, format: .dateTime.day())
                    .font(isToday ? .headline.weight(.bold) : .subheadline.weight(.semibold))
                    .foregroundStyle(numberColor)
            }
            .frame(width: 40, height: 40)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(accessibilityLabel)
    }

    /// VoiceOver label: date, calories vs. target, and the state word so color
    /// is never the only signal — e.g. "July 8, 1,489 of 2,000 calories, on target".
    /// Today wraps the same state word with "so far" and "in progress".
    private var accessibilityLabel: Text {
        let day = Text(date, format: .dateTime.month(.wide).day())
        if isToday {
            let today = String(localized: "today, in progress")
            guard let kcal else { return Text("\(day), \(today)") }
            guard let goal = calorieGoal, goal > 0 else {
                return Text("\(day), \(Format.kcal(kcal)) calories so far, \(today)")
            }
            return Text("\(day), \(Format.kcal(kcal)) of \(Format.kcal(goal)) calories so far, \(ringState.name), \(today)")
        }
        guard let kcal else { return day }
        guard let goal = calorieGoal, goal > 0 else {
            return Text("\(day), \(Format.kcal(kcal)) calories")
        }
        return Text("\(day), \(Format.kcal(kcal)) of \(Format.kcal(goal)) calories, \(ringState.name)")
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack(spacing: 0) {
            // Today, in progress: soft tinted disc + bold green number, with a
            // ring scored live (here 85% → green) as the day fills.
            CalendarDayCell(date: Date(), kcal: 1700, calorieGoal: 2000,
                            isToday: true, isFuture: false) {}
            // On target (80–105%): green, filled to actual percentage.
            CalendarDayCell(date: Date(), kcal: 1900, calorieGoal: 2000,
                            isToday: false, isFuture: false) {}
            // Under (< 80%): muted gray, partial fill.
            CalendarDayCell(date: Date(), kcal: 900, calorieGoal: 2000,
                            isToday: false, isFuture: false) {}
            // Over (> 105%): amber, fully filled.
            CalendarDayCell(date: Date(), kcal: 2600, calorieGoal: 2000,
                            isToday: false, isFuture: false) {}
            // No target: neutral gray fallback.
            CalendarDayCell(date: Date(), kcal: 1500, calorieGoal: nil,
                            isToday: false, isFuture: false) {}
            // Future / empty: no ring.
            CalendarDayCell(date: Date(), kcal: nil, calorieGoal: 2000,
                            isToday: false, isFuture: true) {}
        }
        .padding(16)
    }
}
