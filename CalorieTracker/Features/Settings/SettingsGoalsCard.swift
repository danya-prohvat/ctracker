import SwiftUI

/// "My goals" card: pushes the goals & nutrients screens with a one-line
/// summary of the current daily goal. Macros are shown as colored dots in
/// the ring palette (protein / fat / carbs) instead of the "P · F · C"
/// letters (user decision 2026-11-12); VoiceOver still reads the letters.
struct SettingsGoalsCard: View {
    let settings: UserSettings

    var body: some View {
        // One row like the prototype — GoalsView embeds the nutrients section.
        NavigationLink {
            GoalsView()
        } label: {
            goalsRow
        }
        .buttonStyle(.plain)
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    private var goalsRow: some View {
        HStack(spacing: 12) {
            SettingsRowIcon(systemName: "target", tint: Theme.tileGreen)
            VStack(alignment: .leading, spacing: 3) {
                Text("Goals & nutrients")
                    .font(.callout)
                    .foregroundStyle(Theme.textPrimary)
                summary
            }
            Spacer(minLength: 12)
            SettingsRowChevron()
        }
        .settingsIconRowPadding()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    // Same nil fallbacks as GoalsView (model defaults).
    private var kcal: String { Format.kcal(settings.calorieGoal ?? 2000) }
    private var protein: String { Format.amount(settings.proteinGoal ?? 150) }
    private var fat: String { Format.amount(settings.fatGoal ?? 67) }
    private var carbs: String { Format.amount(settings.carbGoal ?? 200) }

    private var summary: some View {
        HStack(spacing: 8) {
            Text("\(kcal) kcal")
            macro(Theme.protein, protein)
            macro(Theme.fat, fat)
            macro(Theme.carbs, carbs)
        }
        .font(.footnote)
        .foregroundStyle(Theme.textSecondary)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }

    private func macro(_ color: Color, _ value: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(value) g")
        }
    }

    private var accessibilitySummary: Text {
        Text("Goals & nutrients") + Text(verbatim: ", ")
            + Text("\(kcal) kcal · \(protein) P · \(fat) F · \(carbs) C")
    }
}
