import SwiftUI

/// Calories ring of the goals plan editor (user decision 2026-11-12): three
/// butt-joined arcs sized by each macro's share of calories (P·4 / F·9 / C·4)
/// in the Today ring colors, starting at 12 o'clock and running clockwise.
/// Deliberately not mirrored under RTL, like `ProgressRing`. An all-zero plan
/// shows only the track.
struct MacroSplitRing: View {
    var protein: Double
    var fat: Double
    var carbs: Double
    var lineWidth: CGFloat

    private var shares: (p: Double, f: Double, c: Double) {
        let p = protein * 4, f = fat * 9, c = carbs * 4
        let total = p + f + c
        guard total > 0 else { return (0, 0, 0) }
        return (p / total, f / total, c / total)
    }

    var body: some View {
        let s = shares
        ZStack {
            Circle()
                .stroke(Theme.ringTrack, lineWidth: lineWidth)
            arc(from: 0, to: s.p, color: Theme.protein)
            arc(from: s.p, to: s.p + s.f, color: Theme.fat)
            arc(from: s.p + s.f, to: s.p + s.f + s.c, color: Theme.carbs)
        }
        .padding(lineWidth / 2)
        .animation(.snappy(duration: 0.4), value: protein)
        .animation(.snappy(duration: 0.4), value: fat)
        .animation(.snappy(duration: 0.4), value: carbs)
        .accessibilityHidden(true)
    }

    private func arc(from: Double, to: Double, color: Color) -> some View {
        Circle()
            .trim(from: min(from, 1), to: min(to, 1))
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            .rotationEffect(.degrees(-90))
    }
}

/// Dot legend under the ring: "● 30% Protein · ● 30% Fat · ● 40% Carbs" with
/// the largest-remainder percents (always sum to 100) and locale-aware "%".
struct MacroSplitLegend: View {
    var protein: Double
    var fat: Double
    var carbs: Double

    var body: some View {
        let pct = NutritionMath.macroCaloriePercents(protein: protein, fat: fat, carbs: carbs)
        HStack(spacing: 14) {
            item(pct.p, Theme.protein, "Protein")
            item(pct.f, Theme.fat, "Fat")
            item(pct.c, Theme.carbs, "Carbs")
        }
        .font(.caption)
        .foregroundStyle(Theme.textDim)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityElement(children: .combine)
    }

    private func item(_ percent: Int, _ color: Color, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(Double(percent) / 100, format: .percent.precision(.fractionLength(0)))
                + Text(verbatim: " ")
                + Text(title)
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 16) {
            MacroSplitRing(protein: 150, fat: 67, carbs: 200, lineWidth: 13)
                .frame(width: 150, height: 150)
            MacroSplitLegend(protein: 150, fat: 67, carbs: 200)
        }
        .padding(22)
        .glassCard(cornerRadius: 20)
        .padding(20)
    }
}

#Preview("Dark") {
    ZStack {
        AppBackground()
        VStack(spacing: 16) {
            MacroSplitRing(protein: 150, fat: 67, carbs: 200, lineWidth: 13)
                .frame(width: 150, height: 150)
            MacroSplitLegend(protein: 150, fat: 67, carbs: 200)
        }
        .padding(22)
        .glassCard(cornerRadius: 20)
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
