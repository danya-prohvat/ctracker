import SwiftUI

/// "My goals" card: pushes the goals & nutrients screens with a one-line
/// summary of the current daily goal (prototype: "2,200 kcal · 130 P · 70 F · 260 C").
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
            VStack(alignment: .leading, spacing: 2) {
                Text("Goals & nutrients")
                    .font(.callout)
                    .foregroundStyle(Theme.textPrimary)
                summary
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 12)
            SettingsRowChevron()
        }
        .settingsRowPadding()
        .contentShape(Rectangle())
    }

    private var summary: Text {
        // Same nil fallbacks as GoalsView (model defaults).
        let kcal = Format.kcal(settings.calorieGoal ?? 2000)
        let protein = Format.amount(settings.proteinGoal ?? 150)
        let fat = Format.amount(settings.fatGoal ?? 67)
        let carbs = Format.amount(settings.carbGoal ?? 200)
        return Text("\(kcal) kcal · \(protein) P · \(fat) F · \(carbs) C")
    }
}
