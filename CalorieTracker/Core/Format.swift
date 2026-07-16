import Foundation

/// Locale-aware number formatting (spec §2.4 — grouping follows the user's locale).
/// The app shows at most one decimal place (user decision 2026-07-16, replaces
/// the earlier whole-numbers rule): display, edit-prefill and parse all round
/// to a single fraction digit; whole values render without a trailing ".0".
enum Format {
    /// Rounds to the single decimal place the app works in.
    static func round1(_ value: Double) -> Double { (value * 10).rounded() / 10 }

    /// Compact number for display: up to one decimal place.
    static func amount(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        return f.string(from: NSNumber(value: value)) ?? String(round1(value))
    }

    /// kcal, up to one decimal place.
    static func kcal(_ value: Double) -> String {
        amount(value)
    }

    /// Grams with a "g" suffix used in macro captions.
    static func grams(_ value: Double) -> String {
        amount(value) + " g"
    }

    /// A nutrient value with its fixed unit label.
    static func nutrient(_ value: Double, unit: NutrientUnit) -> String {
        amount(value) + " " + unit.label
    }

    /// A logged quantity: canonical g / ml rendered in the user's unit system
    /// ("150 g" / "5 oz" / "34 fl oz"), whole numbers per the integers rule.
    /// Storage stays canonical (spec §3) — this converts at display time only.
    static func quantity(_ canonical: Double, basis: Basis, unitSystem: UnitSystem) -> String {
        let unit = unitSystem.defaultUnit(for: basis)
        return amount(canonical / unit.toCanonical) + " " + unit.label
    }

    /// Value for a text field: up to one decimal place, no grouping.
    static func editable(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.maximumFractionDigits = 1
        return f.string(from: NSNumber(value: value)) ?? String(round1(value))
    }

    /// Parse user-typed input honoring the current locale separator. Extra
    /// fraction digits (pasted or legacy) round to the app's single decimal.
    static func parse(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale.current
        if let n = f.number(from: trimmed) { return round1(n.doubleValue) }
        // Fallback: accept both separators.
        return Double(trimmed.replacingOccurrences(of: ",", with: ".")).map(round1)
    }
}
