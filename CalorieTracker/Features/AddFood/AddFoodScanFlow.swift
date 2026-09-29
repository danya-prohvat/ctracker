import SwiftUI

/// Scanner wiring for the add-food flow: launch gating (a welcome pool of
/// free scans, then a daily quota — `PremiumGate.scanAllowance`), scan
/// counting and routing of scan outcomes into a modal step.
extension AddFoodSheet {
    var scanFlow: some View {
        ScanFlowView(
            startsLocked: scannerStartsLocked,
            onLocalProduct: { product in
                // Re-scanning a product already in the user's base is free:
                // no counter tick and no rewarded ad (user decision
                // 2026-08-03) — the lookup never left the device.
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
                // Not-found and denied paths never tick the counter: only
                // scans that actually found a product count against the free
                // limit (user decision 2026-08-03).
                pendingScan = .newProduct(NewProductRoute(barcode: barcode.isEmpty ? nil : barcode))
                showScanner = false
            }
        )
    }

    /// Free tier: `PremiumGate.freeScanLimit` welcome scans, then
    /// `dailyFreeScanLimit` per day (user decision 2026-09-28). Used up → the
    /// scanner opens on its limit screen (upgrade / manual entry) instead of
    /// the camera; the paywall is presented from inside the flow.
    func startScan() {
        // A route left over from an earlier session must never fire when this
        // scanner cover closes.
        pendingScan = nil
        scannerStartsLocked = settings.map { !PremiumGate.isUnlocked(.scanner, settings: $0) } ?? false
        showScanner = true
    }

    private func countScan() {
        guard let settings else { return }
        PremiumGate.recordSuccessfulScan(settings: settings)
        try? context.save()
    }

    private func loggable(from prefill: ScanPrefill) -> LoggableFood {
        LoggableFood(
            productID: nil, name: prefill.name, basis: prefill.basis,
            per100Calories: prefill.calories, per100Protein: prefill.protein,
            per100Fat: prefill.fat, per100Carbs: prefill.carbs,
            per100Micros: prefill.micros, lastQuantity: nil,
            wasScanned: !prefill.barcode.isEmpty
        )
    }
}
