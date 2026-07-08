import SwiftUI

/// Averages for the current calendar week, per day that has entries.
struct CalendarWeekStats {
    var avgCalories: Double
    var avgProtein: Double
}

/// Two frosted stat cards under the month grid (prototype: radius 18,
/// padding 16/18): average calories and average protein for this week.
struct CalendarWeekStatsRow: View {
    let stats: CalendarWeekStats?

    var body: some View {
        HStack(spacing: 12) {
            statCard(caption: "Avg calories") {
                Text(verbatim: Format.kcal(stats?.avgCalories ?? 0))
                    .font(.stat(.title))
                    .foregroundStyle(Theme.textPrimary)
            }
            statCard(caption: "Avg protein") {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    // Prototype shows the weekly average as whole grams.
                    Text(verbatim: Format.amount((stats?.avgProtein ?? 0).rounded()))
                        .font(.stat(.title))
                        .foregroundStyle(Theme.textPrimary)
                    Text("g")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
    }

    private func statCard(
        caption: LocalizedStringKey,
        @ViewBuilder value: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(caption)
                .font(.footnote)
                .textCase(.uppercase)
                .foregroundStyle(Theme.textSecondary)
            value()
                .padding(.top, 4)
            Text("this week")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .glassCard(cornerRadius: 18)
    }
}

#Preview {
    ZStack {
        AppBackground()
        CalendarWeekStatsRow(
            stats: CalendarWeekStats(avgCalories: 1840, avgProtein: 96)
        )
        .padding(16)
    }
}
