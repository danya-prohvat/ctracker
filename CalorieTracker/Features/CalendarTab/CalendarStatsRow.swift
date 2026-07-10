import SwiftUI

/// Per-day averages over a period, computed only across days that have entries.
struct CalendarPeriodStats {
    var avgCalories: Double
    var avgProtein: Double
    var avgFat: Double
    var avgCarbs: Double
}

/// Daily targets the averages are compared against — drives the "avg / goal"
/// line and the progress bar. Any goal may be absent.
struct CalendarStatGoals {
    var calories: Double?
    var protein: Double?
    var fat: Double?
    var carbs: Double?
}

/// A 2×2 grid of stat cards under the grid: average calories, protein, fat and
/// carbs for the shown period. Each card has a macro-colored icon (identity), a
/// neutral "avg / goal" value and a progress bar toward the goal. The *bar*
/// carries the status color via the same `CalendarRingState` as the grid rings
/// (neutral under, green on target, amber over) so cards and grid share one
/// visual language. Cards are read-only — the segmented picker switches week/month.
struct CalendarStatsRow: View {
    let stats: CalendarPeriodStats?
    let goals: CalendarStatGoals
    /// Localized label of the averaged period, e.g. "July" or "Jul 6 – 12".
    let caption: Text

    /// One rendered card: macro identity (icon + tint), pre-formatted strings,
    /// and the goal progress with its `CalendarRingState` bar color.
    private struct StatValue {
        let title: LocalizedStringKey
        let icon: String
        let tint: Color
        let value: String
        let goal: String?
        let unit: LocalizedStringKey?
        /// avg / goal clamped to 0…1; `nil` when no goal (bar hidden).
        let progress: Double?
        let barColor: Color
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
            makeValue("Avg calories", icon: "flame.fill", tint: Theme.accent,
                      avg: stats?.avgCalories, goal: goals.calories, unit: nil, isCalorie: true),
            makeValue("Avg protein", icon: "fork.knife", tint: Theme.protein,
                      avg: stats?.avgProtein, goal: goals.protein, unit: "g"),
            makeValue("Avg fat", icon: "drop.fill", tint: Theme.fat,
                      avg: stats?.avgFat, goal: goals.fat, unit: "g"),
            makeValue("Avg carbs", icon: "leaf.fill", tint: Theme.carbs,
                      avg: stats?.avgCarbs, goal: goals.carbs, unit: "g"),
        ]
    }

    private func makeValue(
        _ title: LocalizedStringKey,
        icon: String,
        tint: Color,
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
        let progress: Double?
        if let goal, goal > 0 { progress = min(1, consumed / goal) } else { progress = nil }
        return StatValue(
            title: title,
            icon: icon,
            tint: tint,
            value: format(consumed),
            goal: goal.map(format),
            unit: unit,
            progress: progress,
            barColor: CalendarRingState(consumed: consumed, target: goal).color
        )
    }

    private func statCard(_ item: StatValue) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(item)
            valueLine(item)
                .padding(.top, 10)
            if let progress = item.progress {
                progressBar(fraction: progress, color: item.barColor)
                    .padding(.top, 12)
            }
            caption
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .glassCard(cornerRadius: 18)
    }

    private func header(_ item: StatValue) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(item.tint)
                .frame(width: 26, height: 26)
                .background(item.tint.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(item.title)
                .font(.footnote)
                .textCase(.uppercase)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 0)
        }
    }

    /// "1 728 / 2 000 g" — neutral average, muted "/ goal" and unit. Shrinks to
    /// fit the half-width card rather than truncating.
    private func valueLine(_ item: StatValue) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(verbatim: item.value)
                .font(.stat(.title))
                .foregroundStyle(Theme.textPrimary)
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

    /// Thin capsule filled to `fraction` in the status color; fills from the
    /// leading edge (RTL-aware). Track matches the grid rings.
    private func progressBar(fraction: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.ringTrack)
                Capsule()
                    .fill(color)
                    .frame(width: min(1, max(0, fraction)) * geo.size.width)
            }
        }
        .frame(height: 6)
        .animation(.snappy, value: fraction)
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
                caption: Text(verbatim: "July")
            )
            CalendarStatsRow(
                stats: CalendarPeriodStats(avgCalories: 2450, avgProtein: 96,
                                           avgFat: 60, avgCarbs: 210),
                goals: CalendarStatGoals(calories: 2000, protein: 150, fat: 67, carbs: nil),
                caption: Text(verbatim: "Jul 6 – 12")
            )
        }
        .padding(16)
    }
}
