import SwiftUI

/// Consistent kcal ↔ macros plan editor (spec §5), shared by the onboarding
/// result step and the Goals & nutrients settings page. Prototype: a glass
/// card with a full ring + 44 pt steppers for calories (step 50), then a rows
/// card with 30 pt steppers per macro (step 5). See `GoalsPlanEditorRows`.
///
/// Identity: calories = protein×4 + fat×9 + carbs×4. Source of truth is
/// whatever the user touched last:
/// - Editing CALORIES scales all three macros proportionally (protein ≥ 30 g,
///   fat ≥ 20 g while scaling down), rounds them to whole grams, then
///   overwrites calories with the exact sum — see `GoalsPlanMath`.
/// - Editing a MACRO recomputes calories and never touches the other two.
///
/// Validation is soft: extreme values only show a delicate gray hint.
struct PlanEditor: View {
    @Binding var calories: Double
    @Binding var protein: Double
    @Binding var fat: Double
    @Binding var carbs: Double

    enum Field: Hashable {
        case calories, protein, fat, carbs
    }

    @FocusState var focused: Field?
    @State private var texts: [Field: String] = [:]
    @State private var suppressFocusCommit = false

    init(
        calories: Binding<Double>,
        protein: Binding<Double>,
        fat: Binding<Double>,
        carbs: Binding<Double>
    ) {
        _calories = calories
        _protein = protein
        _fat = fat
        _carbs = carbs
    }

    var body: some View {
        VStack(spacing: 12) {
            caloriesCard
            macroRowsCard
            captionBlock
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = nil }
            }
        }
        .onChange(of: focused) { oldValue, newValue in
            if suppressFocusCommit {
                suppressFocusCommit = false
                return
            }
            // Commit when the keyboard is dismissed (Done, scroll, tap away).
            if let oldValue, newValue == nil {
                commit(oldValue)
            }
        }
    }

    // MARK: - Editing plumbing (also used by GoalsPlanEditorRows)

    func textBinding(_ field: Field) -> Binding<String> {
        Binding(
            get: { texts[field] ?? "" },
            set: { texts[field] = $0 }
        )
    }

    func beginEdit(_ field: Field) {
        // Switching directly between fields: commit the previous one first.
        if let current = focused, current != field {
            commit(current)
        }
        let v = value(for: field)
        texts[field] = v == 0 ? "" : Format.editable(field == .calories ? v.rounded() : v)
        focused = field
    }

    /// Synchronously commit and dismiss an in-progress edit (before a stepper
    /// tap changes values underneath it).
    private func blurAndCommit() {
        guard let current = focused else { return }
        suppressFocusCommit = true
        focused = nil
        commit(current)
    }

    private func commit(_ field: Field) {
        guard let parsed = Format.parse(texts[field] ?? ""), parsed >= 0 else { return }
        switch field {
        case .calories: applyCalories(parsed)
        case .protein, .fat, .carbs: setMacro(field, to: parsed)
        }
    }

    func adjustCalories(by delta: Double) {
        blurAndCommit()
        applyCalories(max(0, calories + delta))
    }

    func adjustMacro(_ field: Field, by delta: Double) {
        blurAndCommit()
        setMacro(field, to: max(0, value(for: field) + delta))
    }

    /// Macro changed → recompute calories, leave the other two macros alone.
    private func setMacro(_ field: Field, to newValue: Double) {
        switch field {
        case .protein: protein = newValue
        case .fat: fat = newValue
        case .carbs: carbs = newValue
        case .calories: break
        }
        calories = NutritionMath.calories(protein: protein, fat: fat, carbs: carbs)
    }

    /// Calories changed → scale macros proportionally, round to whole grams,
    /// then overwrite calories with the exact sum of the rounded macros.
    private func applyCalories(_ target: Double) {
        let scaled = GoalsPlanMath.macros(
            forCalories: target, protein: protein, fat: fat, carbs: carbs
        )
        protein = scaled.protein
        fat = scaled.fat
        carbs = scaled.carbs
        calories = NutritionMath.calories(protein: protein, fat: fat, carbs: carbs)
    }

    func value(for field: Field) -> Double {
        switch field {
        case .calories: return calories
        case .protein: return protein
        case .fat: return fat
        case .carbs: return carbs
        }
    }
}

// MARK: - Preview

fileprivate struct PlanEditorPreviewHost: View {
    @State private var calories: Double = 2148
    @State private var protein: Double = 126
    @State private var fat: Double = 60
    @State private var carbs: Double = 276

    var body: some View {
        ZStack {
            AppBackground()
            PlanEditor(calories: $calories, protein: $protein, fat: $fat, carbs: $carbs)
                .padding(20)
        }
    }
}

#Preview {
    PlanEditorPreviewHost()
}
