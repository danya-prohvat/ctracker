import Foundation
import SwiftData

/// Barcode-aware product persistence — the single place enforcing
/// "one saved product per barcode".
///
/// CloudKit compatibility forbids `@Attribute(.unique)`, so dedup happens here
/// in code: fetch first, update in place when a product with the same barcode
/// already exists, insert otherwise. Updating the live product never rewrites
/// history — diary entries hold frozen snapshots (spec §2.1).
enum ProductStore {

    /// First saved product carrying this barcode, if any.
    static func existing(barcode: String?, in context: ModelContext) -> Product? {
        guard let barcode, !barcode.isEmpty else { return nil }
        let target: String? = barcode
        var descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { $0.barcode == target }
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// Inserts a new product — or, when one with the same barcode is already
    /// saved, updates that one in place instead of creating a twin. Returns
    /// the product actually persisted.
    static func upsert(
        name: String,
        basis: Basis,
        calories: Double,
        protein: Double,
        fat: Double,
        carbs: Double,
        micros: [String: Double],
        barcode: String?,
        in context: ModelContext
    ) -> Product {
        if let product = existing(barcode: barcode, in: context) {
            product.name = name
            product.basis = basis
            product.calories = calories
            product.protein = protein
            product.fat = fat
            product.carbs = carbs
            product.micros = micros
            try? context.save()
            return product
        }
        let product = Product(
            name: name, basis: basis,
            calories: calories, protein: protein, fat: fat, carbs: carbs,
            micros: micros, barcode: barcode
        )
        context.insert(product)
        try? context.save()
        return product
    }
}
