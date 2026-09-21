import SwiftUI

/// A macro (protein / fat / carbs) consumed-vs-goal value. The ring colors
/// come from the macro's accent via `TodayRingStyle` — see `MacroRing.style`.
struct MacroValue {
    let titleKey: LocalizedStringKey
    let consumed: Double
    let goal: Double?
    /// Share of the day's macro calories (0–100). Non-nil switches the ring
    /// to "% of calories" mode (spec §6) — set by tapping the rings.
    var caloriePercent: Int? = nil
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
        if let percent = value.caloriePercent { return Double(percent) / 100 }
        guard let goal = value.goal, goal > 0 else { return 0 }
        return min(value.consumed / goal, 1)
    }

    /// Accent arc over a tinted track; amber when over 105% of the goal —
    /// the same over-threshold as the calendar rings. The calorie-share mode
    /// has no goal, so it always stays in the accent color.
    private var style: TodayRingStyle {
        TodayRingStyle(accent: accent, consumed: value.consumed,
                       goal: value.caloriePercent == nil ? value.goal : nil)
    }

    /// Center number: grams eaten, or the share of calories in percent mode
    /// (locale-aware percent — "31%", "31 %", "%31").
    private var centerText: Text {
        if let percent = value.caloriePercent {
            return Text(Double(percent) / 100, format: .percent.precision(.fractionLength(0)))
        }
        return Text(verbatim: Format.amount(value.consumed.rounded()))
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 6,
                             color: style.color, trackColor: style.track)
                centerText
                    .font(.stat(.subheadline))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: value.consumed)
                    .padding(.horizontal, 10)
            }
            .frame(width: 68, height: 68)

            Text(value.titleKey)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textStrong)

            if value.caloriePercent != nil {
                Text("of calories")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            } else if let goal = value.goal {
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
            carbs: MacroValue(titleKey: "Carbs", consumed: 240, goal: 200,
                              caloriePercent: 51)
        )
        .padding(22)
        .glassCard()
        .padding(20)
    }
}
