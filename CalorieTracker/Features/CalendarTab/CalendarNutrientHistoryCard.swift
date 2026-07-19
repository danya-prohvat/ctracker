import SwiftUI

/// Per-nutrient averages for the visible calendar period, under the macro stat
/// cards. Collapsed it names the period being averaged; expanded it lists each
/// tracked nutrient with its mean daily intake vs the goal, reusing
/// `NutrientProgressRow` so the calendar and the day detail read identically.
/// The caller hides it when the period has no tracked-nutrient data.
struct CalendarNutrientHistoryCard: View {
    let averages: [NutrientPeriodAverage]
    /// Localized label of the averaged period, e.g. "July" or "Jul 6 – 12".
    let caption: Text

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if isExpanded {
                VStack(spacing: 16) {
                    ForEach(averages) { avg in
                        NutrientProgressRow(def: avg.def, consumed: avg.average, goal: avg.goal)
                    }
                }
                .padding(.top, 16)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 18)
    }

    private var header: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nutrients")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Avg per day · \(caption)")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    Text(isExpanded ? "Hide" : "Show")
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Nutrients")
        .accessibilityHint(isExpanded ? "Collapses the list" : "Expands the list")
    }
}

#Preview {
    let samples: [(String, Double, Double?)] = [
        ("fiber", 22, 28), ("sugar", 61, 50),
        ("sodium", 2450, 2300), ("calcium", 940, 1300),
    ]
    let averages = samples.compactMap { id, avg, goal in
        NutrientCatalog.def(id).map { NutrientPeriodAverage(def: $0, average: avg, goal: goal) }
    }
    return ZStack {
        AppBackground()
        ScrollView {
            CalendarNutrientHistoryCard(averages: averages, caption: Text(verbatim: "July"))
                .padding(16)
        }
    }
}
