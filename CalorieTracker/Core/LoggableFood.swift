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
    /// Canonical quantity (g / ml) attached to the food, if any. The quantity
    /// screen ignores it (always starts at 100); the log-once fast path uses
    /// it to carry the form's "Per" base amount to write immediately.
    var lastQuantity: Double?
    /// Whether the source came from the barcode scanner (frozen into the diary
    /// snapshot at log time). Defaults to false so existing call sites compile.
    var wasScanned: Bool = false
}
