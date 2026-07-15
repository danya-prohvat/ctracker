import Foundation

/// Locale-aware number formatting (spec §2.4 — grouping follows the user's locale).
/// The app works in whole numbers only (user decision 2026-07-14): every value
/// is rounded to an integer at display, edit-prefill and parse time.
enum Format {
    /// Compact whole number for display.
    static func amount(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value.rounded())) ?? String(Int(value.rounded()))
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

    /// Value for a text field: whole number, no grouping.
    static func editable(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value.rounded())) ?? String(Int(value.rounded()))
    }

    /// Parse user-typed input honoring the current locale separator. Fractions
    /// (pasted or legacy) are rounded — the app stores whole numbers only.
    static func parse(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale.current
        if let n = f.number(from: trimmed) { return n.doubleValue.rounded() }
        // Fallback: accept both separators.
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))?.rounded()
    }
}
