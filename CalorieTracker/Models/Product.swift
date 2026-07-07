import Foundation
import SwiftData

/// A user-created product in their own database (spec §1). Nutrition values are
/// always stored per 100 g / 100 ml. Editing or deleting a product never changes
/// past diary entries — those hold their own snapshot (spec §2.1).
@Model
final class Product {
    var id: UUID = UUID()
    var name: String = ""
    private var basisRaw: String = Basis.per100g.rawValue

    // Nutrition per 100 g / 100 ml.
    var calories: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbs: Double = 0

    /// Optional micronutrient values per 100 g / 100 ml, keyed by NutrientDef.id.
    var micros: [String: Double] = [:]

    var barcode: String? = nil

    /// Last logged quantity in canonical units (g / ml) — used for prefill & Recent chips.
    var lastQuantity: Double? = nil
    /// Last time this product was logged — drives "My products" recency sort & Recent chips.
    var lastLoggedAt: Date? = nil
    var createdAt: Date = Date()

    var basis: Basis {
        get { Basis(rawValue: basisRaw) ?? .per100g }
        set { basisRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        basis: Basis = .per100g,
        calories: Double = 0,
        protein: Double = 0,
        fat: Double = 0,
        carbs: Double = 0,
        micros: [String: Double] = [:],
        barcode: String? = nil,
        lastQuantity: Double? = nil,
        lastLoggedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.basisRaw = basis.rawValue
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.micros = micros
        self.barcode = barcode
        self.lastQuantity = lastQuantity
        self.lastLoggedAt = lastLoggedAt
        self.createdAt = createdAt
    }
}

extension Product {
    /// Snapshot for the quantity/log screen, decoupled from persistence so logging
    /// works whether or not the product is saved to "My products".
    var loggable: LoggableFood {
        LoggableFood(
            productID: id,
            name: name,
            basis: basis,
            per100Calories: calories,
            per100Protein: protein,
            per100Fat: fat,
            per100Carbs: carbs,
            per100Micros: micros,
            lastQuantity: lastQuantity
        )
    }
}
