import SwiftUI

/// Macro rows of `PlanEditor` (user decision 2026-11-12): icon tile in the
/// macro color, title, "600 kcal · 30%" meta line and a share bar on the
/// left; 30 pt steppers around the tappable gram value on the right.
extension PlanEditor {
    func macroRow(_ title: LocalizedStringKey, field: Field) -> some View {
        let style = macroStyle(field)
        return HStack(spacing: 12) {
            SettingsRowIcon(glyph: style.glyph, tint: style.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout)
                    .foregroundStyle(Theme.textPrimary)
                macroMeta(field)
                MacroShareBar(fraction: Double(percent(field)) / 100, color: style.tint)
            }
            Spacer(minLength: 8)
            HStack(spacing: 12) {
                GoalsStepperCircle(.decrement, size: 30, glyphSize: 20) {
                    adjustMacro(field, by: -5)
                }
                macroValue(field)
                GoalsStepperCircle(.increment, size: 30, glyphSize: 20) {
                    adjustMacro(field, by: 5)
                }
            }
        }
        .settingsIconRowPadding()
    }

    /// Food glyphs are template SVGs in the asset catalog (user pick
    /// 2026-11-12 — SF Symbols has no steak/avocado/bread): Lucide `beef`
    /// (ISC) and Phosphor Fill `avocado`/`bread` (MIT); licenses in
    /// `THIRD_PARTY_LICENSES.md`.
    private func macroStyle(_ field: Field) -> (glyph: SettingsRowIcon.Glyph, tint: Color) {
        switch field {
        case .protein: return (.asset("MacroProtein"), Theme.protein)
        case .fat: return (.asset("MacroFat"), Theme.fat)
        case .carbs: return (.asset("MacroCarbs"), Theme.carbs)
        case .calories: return (.symbol("flame.fill"), Theme.accent)
        }
    }

    /// Largest-remainder percent of calories for the macro (sums to 100
    /// across the three rows, matching the ring legend).
    private func percent(_ field: Field) -> Int {
        let pct = NutritionMath.macroCaloriePercents(protein: protein, fat: fat, carbs: carbs)
        switch field {
        case .protein: return pct.p
        case .fat: return pct.f
        case .carbs: return pct.c
        case .calories: return 100
        }
    }

    private func kcal(_ field: Field) -> Double {
        switch field {
        case .protein: return protein * 4
        case .fat: return fat * 9
        case .carbs: return carbs * 4
        case .calories: return calories
        }
    }

    private func macroMeta(_ field: Field) -> some View {
        (Text("\(Format.kcal(kcal(field))) kcal")
            + Text(verbatim: " · ")
            + Text(Double(percent(field)) / 100, format: .percent.precision(.fractionLength(0))))
            .font(.caption)
            .foregroundStyle(Theme.textTertiary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .contentTransition(.numericText())
            .animation(.easeOut(duration: 0.2), value: kcal(field))
    }

    @ViewBuilder
    private func macroValue(_ field: Field) -> some View {
        if focused == field {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: textBinding(field))
                    .keyboardType(.decimalPad)
                    .numericInputLimit(textBinding(field))
                    .multilineTextAlignment(.trailing)
                    .focused($focused, equals: field)
                    .font(.stat(.callout))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 48)
                Text("g")
                    .font(.callout.bold())
                    .foregroundStyle(Theme.textPrimary)
            }
        } else {
            Text("\(Format.amount(value(for: field))) g")
                .font(.stat(.callout))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .frame(minWidth: 52, alignment: .trailing)
                .contentShape(Rectangle())
                .onTapGesture { beginEdit(field) }
        }
    }
}
