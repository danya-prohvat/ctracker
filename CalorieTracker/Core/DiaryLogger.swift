import Foundation
import SwiftData
import UIKit

/// The single writer of diary records: freezes the food's per-100 values into
/// an immutable `DiaryEntry` snapshot (spec §2.1) and refreshes the source
/// product's recency. Shared by the quantity screen and the log-once fast path.
enum DiaryLogger {
    /// `quantity` is canonical g / ml.
    @MainActor
    static func log(_ food: LoggableFood, quantity: Double, dayKey: String, in context: ModelContext) {
        let now = Date()
        let entry = DiaryEntry(
            loggedAt: now,
            dayKey: dayKey,
            productName: food.name,
            basis: food.basis,
            quantity: quantity,
            per100Calories: food.per100Calories,
            per100Protein: food.per100Protein,
            per100Fat: food.per100Fat,
            per100Carbs: food.per100Carbs,
            per100Micros: food.per100Micros,
            productID: food.productID,
            wasScanned: food.wasScanned
        )
        context.insert(entry)

        // Update source product recency/prefill (only if saved).
        if let id = food.productID {
            var descriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let product = try? context.fetch(descriptor).first {
                product.lastQuantity = quantity
                product.lastLoggedAt = now
            }
        }
        try? context.save()

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        if dayKey == DayKey.today {
            ReviewPromptService.checkGreenZone(in: context)
        }
    }
}
