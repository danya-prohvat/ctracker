import SwiftUI

/// A macro (protein / fat / carbs) consumed-vs-goal value with its accent color.
struct MacroValue {
    let titleKey: LocalizedStringKey
    let consumed: Double
    let goal: Double?
    let color: Color
}

/// Three macro mini-rings (prototype variant B), spread space-around.
struct MacroRingsView: View {
    let protein: MacroValue
    let fat: MacroValue
    let carbs: MacroValue

    var body: some View {
        HStack(spacing: 0) {
            MacroRing(value: protein)
            MacroRing(value: fat)
            MacroRing(value: carbs)
        }
    }
}

private struct MacroRing: View {
    let value: MacroValue

    private var progress: Double {
        guard let goal = value.goal, goal > 0 else { return 0 }
        return min(value.consumed / goal, 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 6, color: value.color)
                Text(verbatim: Format.amount(value.consumed.rounded()))
                    .font(.stat(.subheadline))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 68, height: 68)

            Text(value.titleKey)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textStrong)

            if let goal = value.goal {
                Text("of \(Format.grams(goal))")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            } else {
                Text(verbatim: Format.grams(value.consumed))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        AppBackground()
        MacroRingsView(
            protein: MacroValue(titleKey: "Protein", consumed: 62, goal: 150, color: Theme.protein),
            fat: MacroValue(titleKey: "Fat", consumed: 40, goal: 67, color: Theme.fat),
            carbs: MacroValue(titleKey: "Carbs", consumed: 180, goal: 200, color: Theme.carbs)
        )
        .padding(22)
        .glassCard()
        .padding(20)
    }
}
