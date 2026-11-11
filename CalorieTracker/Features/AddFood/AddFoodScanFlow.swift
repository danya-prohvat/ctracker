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
                finishScan(with: .quantity(product.loggable))
            },
            onPrefill: { prefill in
                countScan()
                finishScan(with: .newProduct(
                    NewProductRoute(prefill: loggable(from: prefill), barcode: prefill.barcode)
                ))
            },
            onCreateManually: { barcode in
                // Not-found and denied paths never tick the counter: only
                // scans that actually found a product count (user decision
                // 2026-08-03).
                finishScan(with: .newProduct(NewProductRoute(barcode: barcode.isEmpty ? nil : barcode)))
            }
        )
    }

    /// The lead scanner (opened from Today) hands over in place; the
    /// Scan-tile cover closes first and presents the result once dismissed
    /// (`presentPendingScan`).
    private func finishScan(with kind: AddSheet.Kind) {
        if lead.isScanner {
            finishLeadScan(with: kind)
        } else {
            pendingScan = kind
            showScanner = false
        }
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
