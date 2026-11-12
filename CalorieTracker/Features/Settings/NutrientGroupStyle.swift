import SwiftUI

/// Per-group hue of the Goals & nutrients rows (user decision 2026-11-12):
/// the soft circle behind each nutrient glyph is tinted by its catalog
/// group — macrominerals slate, trace elements teal, vitamins apricot,
/// everything else plum. The glyph itself is per nutrient (`NutrientGlyph`).
extension NutrientGroup {
    var tint: Color {
        switch self {
        case .macromineral: return Theme.nutrientMacromineral
        case .microelement: return Theme.nutrientMicroelement
        case .vitamin: return Theme.nutrientVitamin
        case .other: return Theme.nutrientOther
        }
    }
}
