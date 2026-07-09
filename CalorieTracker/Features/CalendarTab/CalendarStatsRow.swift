import SwiftUI

/// Averages over a period, per day that has entries.
struct CalendarPeriodStats {
    var avgCalories: Double
    var avgProtein: Double
}

/// Two stat cards under the grid (prototype: radius 18, padding 16/18): average
/// calories and average protein for the shown period, with the period as the
/// sub-caption. Tapping either card toggles the week/month view (same control
/// as the segmented picker above).
struct CalendarStatsRow: View {
    let stats: CalendarPeriodStats?
    /// Localized label of the averaged period, e.g. "July" or "Jul 6 – 12".
    let caption: Text
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            statCard(title: "Avg calories") {
                Text(verbatim: Format.kcal(stats?.avgCalories ?? 0))
                    .font(.stat(.title))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
            }
            statCard(title: "Avg protein") {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    // Prototype shows the average as whole grams.
                    Text(verbatim: Format.amount((stats?.avgProtein ?? 0).rounded()))
                        .font(.stat(.title))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                    Text("g")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
    }

    private func statCard(
        title: LocalizedStringKey,
        @ViewBuilder value: () -> some View
    ) -> some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.footnote)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.textSecondary)
                value()
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
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 16) {
            CalendarStatsRow(
                stats: CalendarPeriodStats(avgCalories: 1840, avgProtein: 96),
                caption: Text(verbatim: "Jul 6 – 12"),
                onToggle: {}
            )
            CalendarStatsRow(
                stats: CalendarPeriodStats(avgCalories: 2015, avgProtein: 88),
                caption: Text(verbatim: "July"),
                onToggle: {}
            )
        }
        .padding(16)
    }
}
