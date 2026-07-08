import SwiftUI

/// One month-grid day (prototype: 42pt-high cell, 40pt circle area). A day
/// with logged data draws a 40×40 progress ring (day kcal vs. goal, clamped)
/// behind a 14pt day number; empty and future days show only a muted number.
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

    private var progress: Double {
        guard let kcal, let goal = calorieGoal, goal > 0 else { return 0 }
        return min(1, kcal / goal)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if hasData {
                    ProgressRing(
                        progress: progress,
                        lineWidth: 4,
                        color: isToday ? Theme.calendarRingToday : Theme.calendarRingPast,
                        trackColor: Self.ringTrack
                    )
                }
                Text(date, format: .dateTime.day())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(hasData ? Theme.textPrimary : Theme.calendarDayMuted)
            }
            .frame(width: 40, height: 40)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(Text(date, format: .dateTime.month(.wide).day().year()))
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack(spacing: 0) {
            CalendarDayCell(date: Date(), kcal: 1600, calorieGoal: 2200,
                            isToday: true, isFuture: false) {}
            CalendarDayCell(date: Date(), kcal: 900, calorieGoal: 2200,
                            isToday: false, isFuture: false) {}
            CalendarDayCell(date: Date(), kcal: nil, calorieGoal: 2200,
                            isToday: false, isFuture: true) {}
        }
        .padding(16)
    }
}
