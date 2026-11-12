import SwiftUI

/// What is drawn inside a nutrient's soft circle (user decision 2026-11-12,
/// one unique glyph per catalog entry): minerals show their periodic-table
/// symbol, vitamins their letter with the B-group index as a subscript, and
/// the "other" group a food pictogram from the asset catalog (Phosphor Fill
/// / Lucide, see `THIRD_PARTY_LICENSES.md`). Keyed by the stable catalog
/// `id`; a nutrient added without a glyph falls back to its first letter.
enum NutrientGlyph {
    case text(String, sub: String? = nil)
    case asset(String)
}

extension NutrientDef {
    var glyph: NutrientGlyph {
        switch id {
        case "calcium": return .text("Ca")
        case "phosphorus": return .text("P")
        case "magnesium": return .text("Mg")
        case "sodium": return .text("Na")
        case "potassium": return .text("K")
        case "chloride": return .text("Cl")
        case "iron": return .text("Fe")
        case "zinc": return .text("Zn")
        case "copper": return .text("Cu")
        case "manganese": return .text("Mn")
        case "iodine": return .text("I")
        case "selenium": return .text("Se")
        case "chromium": return .text("Cr")
        case "molybdenum": return .text("Mo")
        case "fluoride": return .text("F")
        case "vitaminA": return .text("A")
        case "vitaminC": return .text("C")
        case "vitaminD": return .text("D")
        case "vitaminE": return .text("E")
        case "vitaminK": return .text("K")
        case "vitaminB1": return .text("B", sub: "1")
        case "vitaminB2": return .text("B", sub: "2")
        case "vitaminB3": return .text("B", sub: "3")
        case "vitaminB5": return .text("B", sub: "5")
        case "vitaminB6": return .text("B", sub: "6")
        case "vitaminB7": return .text("B", sub: "7")
        case "vitaminB9": return .text("B", sub: "9")
        case "vitaminB12": return .text("B", sub: "12")
        case "fiber": return .asset("NutrientFiber")
        case "sugar": return .asset("NutrientSugar")
        case "saturatedFat": return .asset("NutrientSaturatedFat")
        case "transFat": return .asset("NutrientTransFat")
        case "cholesterol": return .asset("NutrientCholesterol")
        case "omega3": return .asset("NutrientOmega3")
        case "omega6": return .asset("NutrientOmega6")
        case "choline": return .asset("NutrientCholine")
        case "caffeine": return .asset("NutrientCaffeine")
        default: return .text(String(id.prefix(1)).uppercased())
        }
    }
}
