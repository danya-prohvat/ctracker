import Foundation

/// OFF nutriment key → our `NutrientDef.id`, with a multiplier converting
/// OFF's per-100 values (always grams) into the fixed catalog unit (mg / µg).
/// Covers every catalog nutrient OFF can provide. The list is ordered: when
/// two OFF keys feed the same nutrient (vitamin-b9 / folates), the first key
/// present on the card wins.
///
/// Sodium is intentionally absent — OFF cards often carry it mis-entered
/// (mg typed into a grams field), so it needs a salt cross-check and is
/// resolved separately in `BarcodeLookupService`.
struct OFFMicroMapping {
    let offKey: String
    let nutrientID: String
    let multiplier: Double

    static let all: [OFFMicroMapping] = [
        // Catalog unit g — OFF grams pass through.
        OFFMicroMapping(offKey: "fiber_100g", nutrientID: "fiber", multiplier: 1),
        OFFMicroMapping(offKey: "sugars_100g", nutrientID: "sugar", multiplier: 1),
        OFFMicroMapping(offKey: "saturated-fat_100g", nutrientID: "saturatedFat", multiplier: 1),
        OFFMicroMapping(offKey: "trans-fat_100g", nutrientID: "transFat", multiplier: 1),
        OFFMicroMapping(offKey: "omega-3-fat_100g", nutrientID: "omega3", multiplier: 1),
        OFFMicroMapping(offKey: "omega-6-fat_100g", nutrientID: "omega6", multiplier: 1),

        // Catalog unit mg — grams × 1 000.
        OFFMicroMapping(offKey: "cholesterol_100g", nutrientID: "cholesterol", multiplier: 1000),
        OFFMicroMapping(offKey: "calcium_100g", nutrientID: "calcium", multiplier: 1000),
        OFFMicroMapping(offKey: "phosphorus_100g", nutrientID: "phosphorus", multiplier: 1000),
        OFFMicroMapping(offKey: "magnesium_100g", nutrientID: "magnesium", multiplier: 1000),
        OFFMicroMapping(offKey: "potassium_100g", nutrientID: "potassium", multiplier: 1000),
        OFFMicroMapping(offKey: "chloride_100g", nutrientID: "chloride", multiplier: 1000),
        OFFMicroMapping(offKey: "iron_100g", nutrientID: "iron", multiplier: 1000),
        OFFMicroMapping(offKey: "zinc_100g", nutrientID: "zinc", multiplier: 1000),
        OFFMicroMapping(offKey: "copper_100g", nutrientID: "copper", multiplier: 1000),
        OFFMicroMapping(offKey: "manganese_100g", nutrientID: "manganese", multiplier: 1000),
        OFFMicroMapping(offKey: "fluoride_100g", nutrientID: "fluoride", multiplier: 1000),
        OFFMicroMapping(offKey: "vitamin-c_100g", nutrientID: "vitaminC", multiplier: 1000),
        OFFMicroMapping(offKey: "vitamin-e_100g", nutrientID: "vitaminE", multiplier: 1000),
        OFFMicroMapping(offKey: "vitamin-b1_100g", nutrientID: "vitaminB1", multiplier: 1000),
        OFFMicroMapping(offKey: "vitamin-b2_100g", nutrientID: "vitaminB2", multiplier: 1000),
        OFFMicroMapping(offKey: "vitamin-pp_100g", nutrientID: "vitaminB3", multiplier: 1000),
        OFFMicroMapping(offKey: "pantothenic-acid_100g", nutrientID: "vitaminB5", multiplier: 1000),
        OFFMicroMapping(offKey: "vitamin-b6_100g", nutrientID: "vitaminB6", multiplier: 1000),
        OFFMicroMapping(offKey: "choline_100g", nutrientID: "choline", multiplier: 1000),
        OFFMicroMapping(offKey: "caffeine_100g", nutrientID: "caffeine", multiplier: 1000),

        // Catalog unit µg — grams × 1 000 000.
        OFFMicroMapping(offKey: "iodine_100g", nutrientID: "iodine", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "selenium_100g", nutrientID: "selenium", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "chromium_100g", nutrientID: "chromium", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "molybdenum_100g", nutrientID: "molybdenum", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "vitamin-a_100g", nutrientID: "vitaminA", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "vitamin-d_100g", nutrientID: "vitaminD", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "vitamin-k_100g", nutrientID: "vitaminK", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "biotin_100g", nutrientID: "vitaminB7", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "vitamin-b9_100g", nutrientID: "vitaminB9", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "folates_100g", nutrientID: "vitaminB9", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "vitamin-b12_100g", nutrientID: "vitaminB12", multiplier: 1_000_000),
    ]
}
