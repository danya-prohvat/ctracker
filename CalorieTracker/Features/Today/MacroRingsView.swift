import SwiftUI

/// A macro (protein / fat / carbs) consumed-vs-goal value. The ring color is
/// derived from the goal progress, not stored — see `MacroRing.ringColor`.
struct MacroValue {
    let titleKey: LocalizedStringKey
    let consumed: Double
    let goal: Double?
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

    /// Same goal-progress semantics as the calendar rings: neutral when under,
    /// green on target, amber over — never the fixed macro accent.
    private var ringColor: Color {
        CalendarRingState(consumed: value.consumed, target: value.goal).color
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 6, color: ringColor)
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
            protein: MacroValue(titleKey: "Protein", consumed: 138, goal: 150),
            fat: MacroValue(titleKey: "Fat", consumed: 40, goal: 67),
            carbs: MacroValue(titleKey: "Carbs", consumed: 240, goal: 200)
        )
        .padding(22)
        .glassCard()
        .padding(20)
    }
}
