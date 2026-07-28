import SwiftUI

/// Everything below the calendar grid for an (at least partially) unlocked
/// period: macro averages, ad banner, nutrient history card, ring legend and
/// the tap hint. Fully-locked periods show `CalendarHistoryLockedCard` instead.
struct CalendarStatsSection: View {
    let stats: CalendarPeriodStats?
    let goals: CalendarStatGoals
    let caption: Text
    let nutrientAverages: [NutrientPeriodAverage]
    let settings: UserSettings?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CalendarStatsRow(stats: stats, goals: goals, caption: caption)
                .padding(.top, 18)

            if let settings {
                AdBannerView(settings: settings)
                    .padding(.top, 12)
            }

            if !nutrientAverages.isEmpty {
                CalendarNutrientHistoryCard(averages: nutrientAverages, caption: caption)
                    .padding(.top, 12)
            }

            CalendarRingLegend()
                .padding(.top, 16)
            Text("Tap a day with a ring to view details.")
                .font(.footnote)
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        ScrollView {
            CalendarStatsSection(
                stats: nil,
                goals: CalendarStatGoals(calories: 2200, protein: 150, fat: 67, carbs: 200),
                caption: Text(verbatim: "July"),
                nutrientAverages: [],
                settings: nil
            )
            .padding(.horizontal, 16)
        }
    }
}
