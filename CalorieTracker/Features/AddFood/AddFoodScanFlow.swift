import SwiftUI

/// Scanner wiring for the add-food flow: launch gating (3 free scans, spec §9),
/// scan counting and routing of scan outcomes into a modal step.
extension AddFoodSheet {
    var scanFlow: some View {
        ScanFlowView(
            onLocalProduct: { product in
                countScan()
                pendingScan = .quantity(product.loggable)
                showScanner = false
            },
            onPrefill: { prefill in
                countScan()
                pendingScan = .newProduct(
                    NewProductRoute(prefill: loggable(from: prefill), barcode: prefill.barcode)
                )
                showScanner = false
            },
            onCreateManually: { barcode in
                // "Add manually instead" from the denied state passes no code —
                // no scan happened, so the free-tier counter must not tick.
                if !barcode.isEmpty { countScan() }
                pendingScan = .newProduct(NewProductRoute(barcode: barcode.isEmpty ? nil : barcode))
                showScanner = false
            }
        )
    }

    /// Free tier gets 3 scans, then the paywall (spec §9).
    func startScan() {
        guard let settings else { showScanner = true; return }
        if PremiumGate.isUnlocked(.scanner, settings: settings) {
            showScanner = true
        } else {
            showPaywall = true
        }
    }

    private func countScan() {
        guard let settings, !PremiumGate.isPremium(settings: settings) else { return }
        settings.scanCount += 1
        try? context.save()
    }

    private func loggable(from prefill: ScanPrefill) -> LoggableFood {
        LoggableFood(
            productID: nil, name: prefill.name, basis: .per100g,
            per100Calories: prefill.calories, per100Protein: prefill.protein,
            per100Fat: prefill.fat, per100Carbs: prefill.carbs,
            per100Micros: prefill.micros, lastQuantity: nil,
            wasScanned: !prefill.barcode.isEmpty
        )
    }
}
