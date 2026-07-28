import SwiftUI

/// A macro (protein / fat / carbs) consumed-vs-goal value. The ring colors
/// come from the macro's accent via `TodayRingStyle` — see `MacroRing.style`.
struct MacroValue {
    let titleKey: LocalizedStringKey
    let consumed: Double
    let goal: Double?
}

/// Three macro mini-rings (prototype variant B), spread space-around, each in
/// its own accent color (user decision 2026-07-21).
struct MacroRingsView: View {
    let protein: MacroValue
    let fat: MacroValue
    let carbs: MacroValue

    var body: some View {
        HStack(spacing: 0) {
            MacroRing(value: protein, accent: Theme.protein)
            MacroRing(value: fat, accent: Theme.fat)
            MacroRing(value: carbs, accent: Theme.carbs)
        }
    }
}

private struct MacroRing: View {
    let value: MacroValue
    let accent: Color

    private var progress: Double {
        guard let goal = value.goal, goal > 0 else { return 0 }
        return min(value.consumed / goal, 1)
    }

    /// Accent arc over a tinted track; amber when over 105% of the goal —
    /// the same over-threshold as the calendar rings.
    private var style: TodayRingStyle {
        TodayRingStyle(accent: accent, consumed: value.consumed, goal: value.goal)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 6,
                             color: style.color, trackColor: style.track)
                Text(verbatim: Format.amount(value.consumed.rounded()))
                    .font(.stat(.subheadline))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText(value: value.consumed))
                    .animation(.snappy, value: value.consumed)
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
