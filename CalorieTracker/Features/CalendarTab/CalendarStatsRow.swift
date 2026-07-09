import SwiftUI

/// Per-day averages over a period, computed only across days that have entries.
struct CalendarPeriodStats {
    var avgCalories: Double
    var avgProtein: Double
    var avgFat: Double
    var avgCarbs: Double
}

/// Daily targets the averages are compared against — drives the "avg / goal"
/// line and the calendar-matching value color. Any goal may be absent.
struct CalendarStatGoals {
    var calories: Double?
    var protein: Double?
    var fat: Double?
    var carbs: Double?
}

/// A 2×2 grid of stat cards under the grid (prototype: radius 18, padding
/// 16/18): average calories, protein, fat and carbs for the shown period. Each
/// card reads "avg / goal" and tints the average with the *same*
/// `CalendarRingState` color as that day's ring (green on target, gray under,
/// amber over) so the cards and the grid share one visual language. The period
/// is the sub-caption; tapping any card toggles week/month (same as the picker).
struct CalendarStatsRow: View {
    let stats: CalendarPeriodStats?
    let goals: CalendarStatGoals
    /// Localized label of the averaged period, e.g. "July" or "Jul 6 – 12".
    let caption: Text
    let onToggle: () -> Void

    /// One rendered card: pre-formatted strings plus its calendar-matching color.
    private struct StatValue {
        let title: LocalizedStringKey
        let value: String
        let goal: String?
        let unit: LocalizedStringKey?
        let color: Color
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(values[0])
                statCard(values[1])
            }
            HStack(spacing: 12) {
                statCard(values[2])
                statCard(values[3])
            }
        }
    }

    private var values: [StatValue] {
        [
            makeValue("Avg calories", avg: stats?.avgCalories, goal: goals.calories,
                      unit: nil, isCalorie: true),
            makeValue("Avg protein", avg: stats?.avgProtein, goal: goals.protein, unit: "g"),
            makeValue("Avg fat", avg: stats?.avgFat, goal: goals.fat, unit: "g"),
            makeValue("Avg carbs", avg: stats?.avgCarbs, goal: goals.carbs, unit: "g"),
        ]
    }

    private func makeValue(
        _ title: LocalizedStringKey,
        avg: Double?,
        goal: Double?,
        unit: LocalizedStringKey?,
        isCalorie: Bool = false
    ) -> StatValue {
        let consumed = avg ?? 0
        // Calories are whole kcal; macros are whole grams.
        let format: (Double) -> String = isCalorie
            ? Format.kcal
            : { Format.amount($0.rounded()) }
        return StatValue(
            title: title,
            value: format(consumed),
            goal: goal.map(format),
            unit: unit,
            color: CalendarRingState(consumed: consumed, target: goal).color
        )
    }

    private func statCard(_ item: StatValue) -> some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 0) {
                Text(item.title)
                    .font(.footnote)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.textSecondary)
                valueLine(item)
                    .padding(.top, 4)
                caption
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassCard(cornerRadius: 18)
    }

    /// "1 728 / 2 000 g" — big colored average, muted "/ goal" and unit. Shrinks
    /// to fit the half-width card rather than truncating.
    private func valueLine(_ item: StatValue) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(verbatim: item.value)
                .font(.stat(.title))
                .foregroundStyle(item.color)
                .contentTransition(.numericText())
            if let goal = item.goal {
                Text(verbatim: "/ \(goal)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textTertiary)
                    // Read "of 2 000", not "slash 2 000".
                    .accessibilityLabel(Text("of \(goal)"))
            }
            if let unit = item.unit {
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 16) {
            CalendarStatsRow(
                stats: CalendarPeriodStats(avgCalories: 1728, avgProtein: 138,
                                           avgFat: 74, avgCarbs: 190),
                goals: CalendarStatGoals(calories: 2000, protein: 150, fat: 67, carbs: 200),
                caption: Text(verbatim: "July"),
                onToggle: {}
            )
            CalendarStatsRow(
                stats: CalendarPeriodStats(avgCalories: 1840, avgProtein: 96,
                                           avgFat: 60, avgCarbs: 210),
                goals: CalendarStatGoals(calories: 2000, protein: 150, fat: 67, carbs: nil),
                caption: Text(verbatim: "Jul 6 – 12"),
                onToggle: {}
            )
        }
        .padding(16)
    }
}
