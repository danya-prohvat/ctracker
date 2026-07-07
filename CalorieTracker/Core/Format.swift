import Foundation

/// Locale-aware number formatting (spec §2.4 — decimal separator follows the user's locale).
enum Format {
    /// Compact number: no decimals for integers, up to 1 fractional digit otherwise.
    static func amount(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = (rounded == rounded.rounded()) ? 0 : 1
        return f.string(from: NSNumber(value: rounded)) ?? String(rounded)
    }

    /// Integer kcal.
    static func kcal(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value.rounded())) ?? String(Int(value.rounded()))
    }

    /// Grams with a "g" suffix used in macro captions.
    static func grams(_ value: Double) -> String {
        amount(value) + " g"
    }

    /// A nutrient value with its fixed unit label.
    static func nutrient(_ value: Double, unit: NutrientUnit) -> String {
        amount(value) + " " + unit.label
    }

    /// Value for a text field: locale decimal separator, no grouping, up to 2 decimals.
    static func editable(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// Parse user-typed decimal input honoring the current locale separator.
    static func parse(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale.current
        if let n = f.number(from: trimmed) { return n.doubleValue }
        // Fallback: accept both separators.
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }
}
