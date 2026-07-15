import SwiftUI
import SwiftData

/// Prototype quantity sheet (spec §5), shared by the add and edit flows:
/// custom header, live glass card and a custom keypad. The input unit is fixed
/// by the global unit-system setting (Settings → Units), no per-entry switcher.
/// Works in canonical g / ml; oz / fl oz convert via `FoodUnit.toCanonical`
/// at input time — commit always receives the canonical quantity.
struct QuantityEditor: View {
    let name: String
    let wasScanned: Bool
    let basis: Basis
    let per100Calories: Double
    let per100Protein: Double
    let per100Fat: Double
    let per100Carbs: Double
    let unit: FoodUnit
    let title: LocalizedStringKey
    let ctaTitle: LocalizedStringKey
    let onBack: () -> Void
    let onClose: (() -> Void)?   // trailing "Close"; hidden when nil
    let onDelete: (() -> Void)?
    let onCommit: (Double) -> Void   // receives canonical quantity (g / ml)

    @State private var text: String

    init(
        name: String,
        wasScanned: Bool = false,
        basis: Basis,
        per100Calories: Double,
        per100Protein: Double,
        per100Fat: Double,
        per100Carbs: Double,
        unitSystem: UnitSystem,
        initialCanonical: Double,
        title: LocalizedStringKey,
        ctaTitle: LocalizedStringKey,
        onBack: @escaping () -> Void,
        onClose: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onCommit: @escaping (Double) -> Void
    ) {
        self.name = name
        self.wasScanned = wasScanned
        self.basis = basis
        self.per100Calories = per100Calories
        self.per100Protein = per100Protein
        self.per100Fat = per100Fat
        self.per100Carbs = per100Carbs
        self.unit = unitSystem.defaultUnit(for: basis)
        self.title = title
        self.ctaTitle = ctaTitle
        self.onBack = onBack
        self.onClose = onClose
        self.onDelete = onDelete
        self.onCommit = onCommit

        _text = State(initialValue: Self.inputString(fromCanonical: initialCanonical, unit: unitSystem.defaultUnit(for: basis)))
    }

    /// Quantity in canonical units (g / ml).
    private var canonical: Double { (Format.parse(text) ?? 0) * unit.toCanonical }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.title.bold())
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    if wasScanned {
                        ScannedBadge(font: .title3.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 20)

                QuantityLiveCard(
                    quantityText: text,
                    unitLabel: unit.label,
                    calories: NutritionMath.scaled(per100: per100Calories, quantity: canonical),
                    protein: NutritionMath.scaled(per100: per100Protein, quantity: canonical),
                    fat: NutritionMath.scaled(per100: per100Fat, quantity: canonical),
                    carbs: NutritionMath.scaled(per100: per100Carbs, quantity: canonical)
                )

                QuantityKeypad(onKey: handleKey)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            QuantityActionBar(
                ctaTitle: ctaTitle,
                isEnabled: canonical > 0,
                onDelete: onDelete,
                onCommit: commit
            )
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.backward")
                            .font(.body.weight(.semibold))
                        Text("Back")
                            .font(.body)
                    }
                }
                .accessibilityLabel("Back")
            }
            if let onClose {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onClose) {
                        Text("Close")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .tint(Theme.accentLabel)
    }

    // MARK: - Commit

    /// Writes the canonical quantity, with a success haptic on confirm.
    private func commit() {
        Haptics.success()
        onCommit(canonical)
    }

    // MARK: - Editing model (prototype key handling)

    private func handleKey(_ key: QuantityKey) {
        Haptics.tap()
        var s = text
        switch key {
        case .backspace:
            s = s.count > 1 ? String(s.dropLast()) : "0"
        case .digit(let digit):
            s = (s == "0") ? "\(digit)" : s + "\(digit)"
        }
        if s.count > Self.maxDigits { s = String(s.prefix(Self.maxDigits)) }
        text = s
    }

    /// Same global sanity cap as `numericInputLimit`: 4 digits (9999 g / ml).
    private static let maxDigits = 4

    /// Keypad string for a canonical amount — whole numbers, clamped to the cap.
    private static func inputString(fromCanonical canonical: Double, unit: FoodUnit) -> String {
        var s = Format.editable(canonical / unit.toCanonical)
        if s.count > maxDigits { s = String(s.prefix(maxDigits)) }
        return s.isEmpty ? "0" : s
    }
}

#Preview("Add quantity") {
    NavigationStack {
        QuantityEditor(
            name: "Chicken breast", basis: .per100g,
            per100Calories: 165, per100Protein: 31, per100Fat: 3.6, per100Carbs: 0,
            unitSystem: .metric, initialCanonical: 150,
            title: "Add quantity", ctaTitle: "Add to today",
            onBack: {}, onCommit: { _ in }
        )
        .background(AppBackground())
    }
    .modelContainer(PreviewData.container)
}
