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

    /// Short label used in "per 100 g" / "per 100 ml".
    var per100Label: LocalizedStringKey { isVolume ? "per 100 ml" : "per 100 g" }

    /// Segmented control label.
    var segmentLabel: LocalizedStringKey { isVolume ? "per 100 ml" : "per 100 g" }

    /// Section header, e.g. "NUTRITION (PER 100 G)".
    var nutritionSectionTitle: LocalizedStringKey {
        isVolume ? "Nutrition (per 100 ml)" : "Nutrition (per 100 g)"
    }
}
