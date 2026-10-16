import StoreKit

/// Prompt-free answer to "does this Apple Account own one of our products?"
/// straight from StoreKit 2 (fixed 2026-10-15).
///
/// `Transaction.currentEntitlements` is served from the device's StoreKit
/// cache and never asks the user to sign in. That matters for the reconcile
/// step: RevenueCat's `syncPurchases()` posts the AppTransaction when the
/// device holds no transaction, and fetching that from the App Store pops the
/// "Apple Account Sign-In Requested" sheet — in TestFlight for a sandbox
/// account — on every activation while the local premium flag disagrees with
/// the backend. Asking StoreKit first keeps that call to devices that really
/// have something to sync.
enum StoreEntitlementProbe {
    /// True when at least one verified, non-revoked current entitlement
    /// exists (auto-renewable subscription or the Lifetime non-consumable).
    static func hasAnyCurrentEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil
            else { continue }
            return true
        }
        return false
    }
}
