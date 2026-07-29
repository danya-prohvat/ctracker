import SwiftUI

/// Nutrition basis chosen when a product is created. Nutrition is always defined
/// per 100 g or per 100 ml, never per serving (see spec §1).
enum Basis: String, Codable, CaseIterable, Identifiable {
    case per100g
    case per100ml

    var id: String { rawValue }
    var isVolume: Bool { self == .per100ml }

    /// Canonical unit for storage/math for this basis: "g" or "ml".
    var canonicalUnit: FoodUnit { isVolume ? .ml : .g }

    /// Reference-amount label for list rows: "per 100 g" or the same canonical
    /// amount in US units ("per 3.5 oz" — 100 g ≈ 3.5 oz, 100 ml ≈ 3.4 fl oz).
    /// Nutrition stays per-100 canonical (spec §3); only the label converts,
    /// so the kcal / macro numbers next to it never distort.
    func per100Label(_ unitSystem: UnitSystem) -> LocalizedStringKey {
        switch (unitSystem, isVolume) {
        case (.metric, false): return "per 100 g"
        case (.metric, true): return "per 100 ml"
        case (.us, false): return "per 3.5 oz"
        case (.us, true): return "per 3.4 fl oz"
        }
    }

    /// Compact fragment for the recent chips' "380 kcal / 100 g" caption.
    /// Localized so the unit symbol can follow the script (e.g. Arabic).
    func per100Compact(_ unitSystem: UnitSystem) -> String {
        switch (unitSystem, isVolume) {
        case (.metric, false): return String(localized: "100 g", comment: "Reference amount: 100 grams")
        case (.metric, true): return String(localized: "100 ml", comment: "Reference amount: 100 milliliters")
        case (.us, false): return String(localized: "3.5 oz", comment: "Reference amount: 3.5 ounces (= 100 g)")
        case (.us, true): return String(localized: "3.4 fl oz", comment: "Reference amount: 3.4 fluid ounces (= 100 ml)")
        }
    }
}
