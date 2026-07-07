import Foundation
import SwiftData

/// One logged item on a specific day (spec §1). Stores a frozen per-100 snapshot
/// plus the logged quantity, so history is immutable (spec §2.1): editing/deleting
/// the source product never changes these numbers, and editing the quantity later
/// still recomputes correctly from the frozen per-100 values.
@Model
final class DiaryEntry {
    var id: UUID = UUID()

    /// Exact log time (local). Belongs to the calendar day of `dayKey` (spec §2.3).
    var loggedAt: Date = Date()
    /// Local calendar day, "yyyy-MM-dd", for efficient per-day / per-month queries.
    var dayKey: String = ""

    // Frozen snapshot of the product at log time.
    var productName: String = ""
    private var basisRaw: String = Basis.per100g.rawValue

    /// Logged quantity in canonical units (g / ml). Editing quantity mutates only this.
    var quantity: Double = 0

    // Per-100 nutrition, frozen at log time.
    var per100Calories: Double = 0
    var per100Protein: Double = 0
    var per100Fat: Double = 0
    var per100Carbs: Double = 0
    var per100Micros: [String: Double] = [:]

    /// Optional link back to the source product (may be nil for log-once or if the
    /// product was later deleted). Never used to recompute nutrition — only for
    /// convenience such as reopening the product.
    var productID: UUID? = nil

    var basis: Basis {
        get { Basis(rawValue: basisRaw) ?? .per100g }
        set { basisRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        loggedAt: Date = Date(),
        dayKey: String,
        productName: String,
        basis: Basis,
        quantity: Double,
        per100Calories: Double,
        per100Protein: Double,
        per100Fat: Double,
        per100Carbs: Double,
        per100Micros: [String: Double] = [:],
        productID: UUID? = nil
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.dayKey = dayKey
        self.productName = productName
        self.basisRaw = basis.rawValue
        self.quantity = quantity
        self.per100Calories = per100Calories
        self.per100Protein = per100Protein
        self.per100Fat = per100Fat
        self.per100Carbs = per100Carbs
        self.per100Micros = per100Micros
        self.productID = productID
    }
}

extension DiaryEntry {
    /// Scale factor from per-100 to the logged quantity.
    private var factor: Double { quantity / 100.0 }

    var calories: Double { per100Calories * factor }
    var protein: Double { per100Protein * factor }
    var fat: Double { per100Fat * factor }
    var carbs: Double { per100Carbs * factor }

    /// Per-quantity value when the snapshot has data for this nutrient.
    /// Nil = "no data" — an absent key is not the same as 0.
    func microValue(_ id: String) -> Double? { per100Micros[id].map { $0 * factor } }

    /// Aggregate-math convenience: missing data contributes nothing to a sum.
    func micro(_ id: String) -> Double { microValue(id) ?? 0 }
}
