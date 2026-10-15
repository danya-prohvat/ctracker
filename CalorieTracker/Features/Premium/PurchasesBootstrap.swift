import Foundation
#if canImport(RevenueCat)
import RevenueCat
#endif

/// Configures the RevenueCat SDK once, as early as possible.
///
/// Called from `CalorieTrackerApp.init()` so the SDK observes StoreKit from
/// process start (fixed 2026-10-15): transactions that finish outside the app
/// — Ask to Buy approvals, renewals, refunds — are delivered to the SDK's
/// transaction listener, and a lazily configured SDK (first created at scene
/// activation) picked them up one activation late. `RevenueCatPurchaseService`
/// calls the same function as a safety net. Compiles to a no-op without the
/// SDK.
enum PurchasesBootstrap {
    static func configureIfNeeded() {
        #if canImport(RevenueCat)
        guard !Purchases.isConfigured, !PurchasesConfig.revenueCatAPIKey.isEmpty else { return }
        Purchases.configure(withAPIKey: PurchasesConfig.revenueCatAPIKey)
        #endif
    }
}
