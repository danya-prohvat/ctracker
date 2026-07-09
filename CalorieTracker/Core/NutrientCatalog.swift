import SwiftUI

/// Fixed unit for a micronutrient (spec §4 — no user choice of unit).
enum NutrientUnit: String, Codable {
    case g
    case mg
    case mcg   // micrograms (µg)

    var label: String {
        switch self {
        case .g: return "g"
        case .mg: return "mg"
        case .mcg: return "µg"
        }
    }
}

/// Settings-screen grouping (spec §4).
enum NutrientGroup: String, Codable, CaseIterable, Identifiable {
    case macromineral
    case microelement
    case vitamin
    case other

    var id: String { rawValue }
    var title: LocalizedStringKey {
        switch self {
        case .macromineral: return "Macrominerals"
        case .microelement: return "Trace elements"
        case .vitamin: return "Vitamins"
        case .other: return "Other"
        }
    }
}

/// How a nutrient target is interpreted. Fixed per nutrient in the catalog —
/// never user-editable.
enum NutrientTargetKind: String, Codable {
    /// "Reach 100%": exceeding is success (vitamins, minerals, fiber…).
    case goal
    /// "Do not exceed": exceeding is a warning (sodium, sugar, sat fat…).
    case limit
}

/// A tracked nutrient definition. Static catalog — values logged into diary entries
/// are snapshotted, so changing a definition never rewrites history (spec §2.1).
struct NutrientDef: Identifiable, Hashable {
    let id: String                 // stable key, also used in Product.micros / DiaryEntry snapshots
    let nameKey: LocalizedStringKey
    let unit: NutrientUnit
    let defaultDV: Double?         // default Daily Value; nil = no default norm (e.g. trans fat)
    let group: NutrientGroup
    let hint: LocalizedStringKey?  // optional helper text shown under the goal field
    var kind: NutrientTargetKind = .goal

    static func == (lhs: NutrientDef, rhs: NutrientDef) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum NutrientCatalog {
    /// All 37 tracked nutrients in canonical order (spec §4).
    static let all: [NutrientDef] = [
        // Macrominerals
        NutrientDef(id: "calcium", nameKey: "Calcium", unit: .mg, defaultDV: 1300, group: .macromineral, hint: nil),
        NutrientDef(id: "phosphorus", nameKey: "Phosphorus", unit: .mg, defaultDV: 1250, group: .macromineral, hint: nil),
        NutrientDef(id: "magnesium", nameKey: "Magnesium", unit: .mg, defaultDV: 420, group: .macromineral, hint: nil),
        NutrientDef(id: "sodium", nameKey: "Sodium", unit: .mg, defaultDV: 2300, group: .macromineral, hint: "salt × 0.4 = sodium", kind: .limit),
        NutrientDef(id: "potassium", nameKey: "Potassium", unit: .mg, defaultDV: 4700, group: .macromineral, hint: nil),
        NutrientDef(id: "chloride", nameKey: "Chloride", unit: .mg, defaultDV: 2300, group: .macromineral, hint: nil),

        // Trace elements
        NutrientDef(id: "iron", nameKey: "Iron", unit: .mg, defaultDV: 18, group: .microelement, hint: nil),
        NutrientDef(id: "zinc", nameKey: "Zinc", unit: .mg, defaultDV: 11, group: .microelement, hint: nil),
        NutrientDef(id: "copper", nameKey: "Copper", unit: .mg, defaultDV: 0.9, group: .microelement, hint: nil),
        NutrientDef(id: "manganese", nameKey: "Manganese", unit: .mg, defaultDV: 2.3, group: .microelement, hint: nil),
        NutrientDef(id: "iodine", nameKey: "Iodine", unit: .mcg, defaultDV: 150, group: .microelement, hint: nil),
        NutrientDef(id: "selenium", nameKey: "Selenium", unit: .mcg, defaultDV: 55, group: .microelement, hint: nil),
        NutrientDef(id: "chromium", nameKey: "Chromium", unit: .mcg, defaultDV: 35, group: .microelement, hint: nil),
        NutrientDef(id: "molybdenum", nameKey: "Molybdenum", unit: .mcg, defaultDV: 45, group: .microelement, hint: nil),
        NutrientDef(id: "fluoride", nameKey: "Fluoride", unit: .mg, defaultDV: 4, group: .microelement, hint: nil),

        // Vitamins
        NutrientDef(id: "vitaminA", nameKey: "Vitamin A", unit: .mcg, defaultDV: 900, group: .vitamin, hint: nil),
        NutrientDef(id: "vitaminC", nameKey: "Vitamin C", unit: .mg, defaultDV: 90, group: .vitamin, hint: nil),
        NutrientDef(id: "vitaminD", nameKey: "Vitamin D", unit: .mcg, defaultDV: 20, group: .vitamin, hint: "1 µg = 40 IU"),
        NutrientDef(id: "vitaminE", nameKey: "Vitamin E", unit: .mg, defaultDV: 15, group: .vitamin, hint: nil),
        NutrientDef(id: "vitaminK", nameKey: "Vitamin K", unit: .mcg, defaultDV: 120, group: .vitamin, hint: nil),
        NutrientDef(id: "vitaminB1", nameKey: "Vitamin B1 (thiamin)", unit: .mg, defaultDV: 1.2, group: .vitamin, hint: nil),
        NutrientDef(id: "vitaminB2", nameKey: "Vitamin B2 (riboflavin)", unit: .mg, defaultDV: 1.3, group: .vitamin, hint: nil),
        NutrientDef(id: "vitaminB3", nameKey: "Vitamin B3 (niacin)", unit: .mg, defaultDV: 16, group: .vitamin, hint: nil),
        NutrientDef(id: "vitaminB5", nameKey: "Vitamin B5 (pantothenic acid)", unit: .mg, defaultDV: 5, group: .vitamin, hint: nil),
        NutrientDef(id: "vitaminB6", nameKey: "Vitamin B6", unit: .mg, defaultDV: 1.7, group: .vitamin, hint: nil),
        NutrientDef(id: "vitaminB7", nameKey: "Vitamin B7 (biotin)", unit: .mcg, defaultDV: 30, group: .vitamin, hint: nil),
        NutrientDef(id: "vitaminB9", nameKey: "Vitamin B9 (folate)", unit: .mcg, defaultDV: 400, group: .vitamin, hint: nil),
        NutrientDef(id: "vitaminB12", nameKey: "Vitamin B12", unit: .mcg, defaultDV: 2.4, group: .vitamin, hint: nil),

        // Other
        NutrientDef(id: "fiber", nameKey: "Fiber", unit: .g, defaultDV: 28, group: .other, hint: nil),
        NutrientDef(id: "sugar", nameKey: "Sugar", unit: .g, defaultDV: 50, group: .other, hint: nil, kind: .limit),
        NutrientDef(id: "saturatedFat", nameKey: "Saturated fat", unit: .g, defaultDV: 20, group: .other, hint: nil, kind: .limit),
        NutrientDef(id: "transFat", nameKey: "Trans fat", unit: .g, defaultDV: nil, group: .other, hint: nil, kind: .limit),
        NutrientDef(id: "cholesterol", nameKey: "Cholesterol", unit: .mg, defaultDV: 300, group: .other, hint: nil, kind: .limit),
        NutrientDef(id: "omega3", nameKey: "Omega-3", unit: .g, defaultDV: 1.6, group: .other, hint: nil),
        NutrientDef(id: "omega6", nameKey: "Omega-6", unit: .g, defaultDV: 17, group: .other, hint: nil),
        NutrientDef(id: "choline", nameKey: "Choline", unit: .mg, defaultDV: 550, group: .other, hint: nil),
        NutrientDef(id: "caffeine", nameKey: "Caffeine", unit: .mg, defaultDV: 400, group: .other, hint: nil, kind: .limit),
    ]

    static let byID: [String: NutrientDef] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func def(_ id: String) -> NutrientDef? { byID[id] }

    static func inGroup(_ group: NutrientGroup) -> [NutrientDef] {
        all.filter { $0.group == group }
    }

    /// Default enabled set at first launch. Deliberately wider than spec §4
    /// (user decision 2026-07-08): the four label-staple nutrients everyone
    /// tracks. Doubles as the free tier — see `PremiumGate.freeNutrientIDs`.
    static let defaultEnabled: Set<String> = ["fiber", "sugar", "sodium", "saturatedFat"]
}
