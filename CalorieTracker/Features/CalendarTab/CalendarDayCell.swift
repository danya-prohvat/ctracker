import SwiftUI

/// One month-grid day (prototype: 42pt-high cell, 40pt circle area). A day
/// with logged data draws a 40×40 progress ring (day kcal vs. target) behind a
/// 14pt day number; empty and future days show only a muted number.
///
/// The ring color reflects how the day compares to the calorie target
/// (`CalendarRingState`): green on target, muted gray when under (or with no
/// target), amber when over. The fill is the actual percentage, except an
/// over day is fully filled. See `CalendarRingLegend` for the key.
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

    /// Today stays identifiable (previously via a brighter ring, now via the
    /// brand-green number) independent of its calorie state.
    private var numberColor: Color {
        if isToday { return Theme.accentLabel }
        return hasData ? Theme.textPrimary : Theme.calendarDayMuted
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if hasData {
                    ProgressRing(
                        progress: progress,
                        lineWidth: 4,
                        color: ringState.color,
                        trackColor: Self.ringTrack
                    )
                }
                Text(date, format: .dateTime.day())
                    .font(.subheadline.weight(.semibold))
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
    private var accessibilityLabel: Text {
        let day = Text(date, format: .dateTime.month(.wide).day())
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
            // On target (80–105%): green, filled to actual percentage.
            CalendarDayCell(date: Date(), kcal: 1900, calorieGoal: 2000,
                            isToday: true, isFuture: false) {}
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
