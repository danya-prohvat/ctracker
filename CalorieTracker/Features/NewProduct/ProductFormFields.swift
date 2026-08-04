import Foundation

/// The product form's editable field state plus every derivation on it
/// (parsing, per-100 normalization). A plain value held in a single `@State`,
/// so `NewProductForm` stays about layout, routing and persistence. Equatable
/// so the form can detect real edits by comparing against the state captured
/// right after the initial load (blank, prefilled or loaded product alike).
struct ProductFormFields: Equatable {
    var name = ""
    var basis: Basis = .per100g
    var perAmountText = "100"
    var caloriesText = ""
    var proteinText = ""
    var fatText = ""
    var carbsText = ""
    var microTexts: [String: String] = [:]

    var caloriesValue: Double? { Format.parse(caloriesText) }

    /// Editable "Per" base amount; the nutrition fields mean "per this many
    /// g/ml". nil while empty/zero — submit stays disabled.
    var perAmount: Double? {
        guard let value = Format.parse(perAmountText), value > 0 else { return nil }
        return value
    }

    /// Storage is canonical per-100 (spec §3): entered values are multiplied
    /// by this on save.
    var per100Factor: Double { 100 / (perAmount ?? 100) }

    var canSubmit: Bool {
        !trimmedName.isEmpty && caloriesValue != nil && perAmount != nil
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    /// Parse the micro fields into per-100 values, dropping empty/invalid input.
    func parsedMicros() -> [String: Double] {
        var out: [String: Double] = [:]
        for (id, text) in microTexts {
            if let value = Format.parse(text), value > 0 { out[id] = value * per100Factor }
        }
        return out
    }

    /// Macro values normalized to per-100.
    func macroValues() -> (cals: Double, p: Double, f: Double, c: Double) {
        ((caloriesValue ?? 0) * per100Factor,
         (Format.parse(proteinText) ?? 0) * per100Factor,
         (Format.parse(fatText) ?? 0) * per100Factor,
         (Format.parse(carbsText) ?? 0) * per100Factor)
    }

    // MARK: - Loading

    /// 0 → empty text: fields are never pre-filled with zeros (spec §5).
    private static func text(_ value: Double) -> String {
        value == 0 ? "" : Format.editable(value)
    }

    mutating func load(product: Product) {
        name = product.name
        basis = product.basis
        caloriesText = Self.text(product.calories)
        proteinText = Self.text(product.protein)
        fatText = Self.text(product.fat)
        carbsText = Self.text(product.carbs)
        microTexts = product.micros.mapValues { Format.editable($0) }
    }

    mutating func load(prefill: LoggableFood) {
        name = prefill.name
        basis = prefill.basis
        caloriesText = Self.text(prefill.per100Calories)
        proteinText = Self.text(prefill.per100Protein)
        fatText = Self.text(prefill.per100Fat)
        carbsText = Self.text(prefill.per100Carbs)
        microTexts = prefill.per100Micros.mapValues { Format.editable($0) }
    }
}
