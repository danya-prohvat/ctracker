import SwiftUI

/// Arc + track colors for the in-progress Today rings (user decision
/// 2026-07-21): the arc keeps its accent color while under/on target and turns
/// amber when over — never red — and the track is the arc color at low opacity
/// (Fitness-style), so rings are never plain gray while the day is still
/// running. Retrospective surfaces (calendar grid, period stats) keep the
/// neutral `CalendarRingState` palette.
struct TodayRingStyle {
    let color: Color
    let track: Color

    init(accent: Color, consumed: Double, goal: Double?) {
        let isOver = CalendarRingState(consumed: consumed, target: goal) == .over
        color = isOver ? Theme.warning : accent
        track = color.opacity(0.18)
    }
}
