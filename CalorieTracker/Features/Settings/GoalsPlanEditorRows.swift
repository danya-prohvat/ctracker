import SwiftUI

/// Cards + caption of `PlanEditor`, split out to keep files small.
/// Prototype: a calories glass card (radius 20, 150 pt full ring, line 13,
/// 44 pt steppers) and a macro rows card (radius 14, hairline separators,
/// 30 pt steppers, bold "130 g" values).
extension PlanEditor {
    var caloriesCard: some View {
        HStack(spacing: 18) {
            GoalsStepperCircle(.decrement, size: 44, glyphSize: 26) {
                adjustCalories(by: -50)
            }
            ZStack {
                ProgressRing(
                    progress: 1,
                    lineWidth: 13,
                    color: Theme.accent,
                    trackColor: Color(hex: 0x3C3C43).opacity(0.1)
                )
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
        .frame(maxWidth: .infinity)
        .padding(22)
        .glassCard(cornerRadius: 20)
    }

    @ViewBuilder
    private var kcalValue: some View {
        if focused == .calories {
            TextField("0", text: textBinding(.calories))
                .keyboardType(.numberPad)
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
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: calories)
                .contentShape(Rectangle())
                .onTapGesture { beginEdit(.calories) }
        }
    }

    var macroRowsCard: some View {
        VStack(spacing: 0) {
            macroRow("Protein", field: .protein)
            rowSeparator
            macroRow("Fat", field: .fat)
            rowSeparator
            macroRow("Carbs", field: .carbs)
        }
        .glassCard(cornerRadius: 14)
    }

    private var rowSeparator: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(height: 1)
    }

    private func macroRow(_ title: LocalizedStringKey, field: Field) -> some View {
        HStack {
            Text(title)
                .font(.callout)
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 8)
            HStack(spacing: 14) {
                GoalsStepperCircle(.decrement, size: 30, glyphSize: 20) {
                    adjustMacro(field, by: -5)
                }
                macroValue(field)
                GoalsStepperCircle(.increment, size: 30, glyphSize: 20) {
                    adjustMacro(field, by: 5)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func macroValue(_ field: Field) -> some View {
        if focused == field {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: textBinding(field))
                    .keyboardType(.numberPad)
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

    var captionBlock: some View {
        let pct = NutritionMath.macroCaloriePercents(protein: protein, fat: fat, carbs: carbs)
        return VStack(spacing: 6) {
            Text("\(pct.p)% P · \(pct.f)% F · \(pct.c)% C")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Theme.textSecondary)
            if calories < 1000 || calories > 6000 {
                Text("Unusual plan — double-check your numbers.")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
