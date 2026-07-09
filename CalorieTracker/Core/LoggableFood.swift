import Foundation

/// A value type carrying everything the quantity screen needs to log something,
/// decoupled from SwiftData so it works for saved products *and* log-once items
/// (spec §5 — "Log once without saving").
struct LoggableFood: Hashable {
    /// Set only for saved products (updates lastQuantity/lastLoggedAt & Recent). nil = log once.
    var productID: UUID?
    var name: String
    var basis: Basis
    var per100Calories: Double
    var per100Protein: Double
    var per100Fat: Double
    var per100Carbs: Double
    var per100Micros: [String: Double]
    /// Last logged canonical quantity (g / ml) for prefill, if any.
    var lastQuantity: Double?
    /// Whether the source came from the barcode scanner (frozen into the diary
    /// snapshot at log time). Defaults to false so existing call sites compile.
    var wasScanned: Bool = false
}
