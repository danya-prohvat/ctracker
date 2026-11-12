import SwiftUI

/// Cards + caption of `PlanEditor`, split out to keep files small.
/// Calories card (radius 20): 44 pt steppers around a 150 pt `MacroSplitRing`
/// whose arcs show the P/F/C calorie split, with a dot legend under it (user
/// decision 2026-11-12, replaces the static full ring and the "30% P · 30% F
/// · 40% C" caption). Macro rows live in `GoalsPlanMacroRow`.
extension PlanEditor {
    var caloriesCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 18) {
                GoalsStepperCircle(.decrement, size: 44, glyphSize: 26) {
                    adjustCalories(by: -50)
                }
                ZStack {
                    MacroSplitRing(protein: protein, fat: fat, carbs: carbs, lineWidth: 13)
                    VStack(spacing: 2) {
                        kcalValue
                        Text("kcal / day")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(width: 150, height: 150)
                GoalsStepperCircle(.increment, size: 44, glyphSize: 26) {
                    adjustCalories(by: 50)
                }
            }
            MacroSplitLegend(protein: protein, fat: fat, carbs: carbs)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 18)
        .glassCard(cornerRadius: 20)
    }

    @ViewBuilder
    private var kcalValue: some View {
        if focused == .calories {
            TextField("0", text: textBinding(.calories))
                .keyboardType(.decimalPad)
                .numericInputLimit(textBinding(.calories), maxDigits: 5)
                .multilineTextAlignment(.center)
                .focused($focused, equals: .calories)
                .font(.stat(.largeTitle))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 104)
        } else {
            Text(Format.kcal(calories))
                .font(.stat(.largeTitle))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: calories)
                .contentShape(Rectangle())
                .onTapGesture { beginEdit(.calories) }
        }
    }

    var macroRowsCard: some View {
        VStack(spacing: 0) {
            macroRow("Protein", field: .protein)
            SettingsRowDivider()
            macroRow("Fat", field: .fat)
            SettingsRowDivider()
            macroRow("Carbs", field: .carbs)
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    /// Soft validation only: extreme plans get a delicate gray hint.
    @ViewBuilder
    var captionBlock: some View {
        if calories < 1000 || calories > 6000 {
            Text("Unusual plan — double-check your numbers.")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity)
        }
    }
}
