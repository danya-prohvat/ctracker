import SwiftUI
import SwiftData

/// Prototype "variant B" summary card: big calorie ring with a "remaining"
/// column, a hairline, three macro mini-rings, and the vitamins & minerals
/// expander inside the same glass card.
struct DaySummaryCard: View {
    let entries: [DiaryEntry]
    let settings: UserSettings?
    let isToday: Bool

    @State private var showPercents = false

    private var calories: Double { entries.reduce(0) { $0 + $1.calories } }
    private var protein: Double { entries.reduce(0) { $0 + $1.protein } }
    private var fat: Double { entries.reduce(0) { $0 + $1.fat } }
    private var carbs: Double { entries.reduce(0) { $0 + $1.carbs } }
    private var fiber: Double { entries.reduce(0) { $0 + $1.micro("fiber") } }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 18) {
                CalorieRingView(consumed: calories, goal: settings?.calorieGoal)
                remainingColumn
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)

            MacroRingsView(
                protein: MacroValue(titleKey: "Protein", consumed: protein,
                                    goal: settings?.proteinGoal, color: Theme.protein),
                fat: MacroValue(titleKey: "Fat", consumed: fat,
                                goal: settings?.fatGoal, color: Theme.fat),
                carbs: MacroValue(titleKey: "Carbs", consumed: carbs,
                                  goal: settings?.carbGoal, color: Theme.carbs)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.snappy) { showPercents.toggle() }
            }

            // Derived metrics (spec §6): tap the mini-rings for the % of
            // calories split; net carbs is shown when enabled in settings.
            if showPercents && calories > 0 {
                let p = NutritionMath.macroCaloriePercents(
                    protein: protein, fat: fat, carbs: carbs)
                Text("P \(p.p)% · F \(p.f)% · C \(p.c)% of calories")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            if settings?.netCarbsEnabled == true {
                Text("Net carbs: \(Format.grams(NutritionMath.netCarbs(carbs: carbs, fiber: fiber)))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }

            if let settings, !settings.enabledNutrients.isEmpty {
                VitaminsMineralsSection(entries: entries, settings: settings)
            }
        }
        .padding(22)
        .glassCard()
    }

    @ViewBuilder
    private var remainingColumn: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Calories")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            if let goal = settings?.calorieGoal {
                let remaining = goal - calories
                Text(Format.kcal(abs(remaining)))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(remaining >= 0 ? Theme.textPrimary : Theme.destructive)
                    .contentTransition(.numericText())
                Group {
                    if remaining >= 0 {
                        if isToday {
                            Text("remaining today")
                        } else {
                            Text("remaining that day")
                        }
                    } else {
                        if isToday {
                            Text("over today")
                        } else {
                            Text("over that day")
                        }
                    }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            } else {
                Text(Format.kcal(calories))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                if isToday {
                    Text("eaten today")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Text("eaten that day")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
}

#Preview {
    DaySummaryPreviewHost()
        .modelContainer(PreviewData.container)
}

private struct DaySummaryPreviewHost: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [DiaryEntry]

    var body: some View {
        ZStack {
            AppBackground()
            DaySummaryCard(
                entries: entries,
                settings: UserSettings.current(in: context),
                isToday: true
            )
            .padding(20)
        }
    }
}
