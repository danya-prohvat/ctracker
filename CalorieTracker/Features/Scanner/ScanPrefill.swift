import Foundation

/// Result of a successful barcode lookup, ready to prefill the new-product form
/// (spec §7). All nutrition values are per 100 g; micros are keyed by
/// `NutrientDef.id` and expressed in our fixed catalog units.
struct ScanPrefill {
    var name: String
    var calories: Double
    var protein: Double
    var fat: Double
    var carbs: Double
    var micros: [String: Double]
    var barcode: String
}
