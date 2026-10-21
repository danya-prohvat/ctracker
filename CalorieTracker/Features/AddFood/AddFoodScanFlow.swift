import SwiftUI

/// Scanner wiring for the add-food flow: scan counting for the rewarded toll
/// (`ScanRewardGate`) and routing of scan outcomes into a modal step.
extension AddFoodSheet {
    var scanFlow: some View {
        ScanFlowView(
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
                // scans that actually found a product count (user decision
                // 2026-08-03).
                pendingScan = .newProduct(NewProductRoute(barcode: barcode.isEmpty ? nil : barcode))
                showScanner = false
            }
        )
    }

    /// Scanning is never limited (user decision 2026-10-19): a free user past
    /// the grace day gets `ScanRewardGate.dailyAdFreeScans` ad-free scans a
    /// day, then each scan costs the opt-in ad inside the flow.
    func startScan() {
        // A route left over from an earlier session must never fire when this
        // scanner cover closes.
        pendingScan = nil
        showScanner = true
    }

    private func countScan() {
        guard let settings else { return }
        ScanRewardGate.recordSuccessfulScan(settings: settings)
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
