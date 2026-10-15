import Foundation

#if canImport(RevenueCat)
import RevenueCat

/// Entitlement verdict → `UserSettings.isPremium`, shared by sync, restore and
/// the customer-info stream (fixed 2026-10-15).
extension RevenueCatPurchaseService {
    /// True while a `syncPurchases` round-trip is running — the activation
    /// sync and the stream must not post the receipt twice at once.
    private static var reconciling = false

    /// Mirrors `info` into the settings without ever revoking blindly.
    ///
    /// - Entitled → premium on.
    /// - Not entitled while the app is already free → nothing to do.
    /// - Not entitled while the app says premium (CloudKit synced the flag
    ///   from another device, or the install predates this identity scheme)
    ///   → first `syncPurchases()`, which posts this Apple Account's receipt
    ///   and recovers subscriptions bought elsewhere. Entitled after that →
    ///   premium on; confirmed not entitled → premium off (the gate trims the
    ///   tracked nutrients forward); a throw (offline) → `isPremium` untouched.
    func reconcile(_ info: CustomerInfo) async {
        if isEntitled(info) {
            apply(true)
            return
        }
        guard settings.isPremium, !Self.reconciling else { return }
        Self.reconciling = true
        defer { Self.reconciling = false }
        guard let synced = try? await Purchases.shared.syncPurchases() else { return }
        apply(isEntitled(synced))
    }

    /// The gate detects a premium→free transition and trims the tracked
    /// nutrient set forward to the free one, so only confirmed verdicts may
    /// reach here (see `reconcile`).
    func apply(_ entitled: Bool) {
        PremiumGate.applyEntitlement(entitled, settings: settings)
    }

    func isEntitled(_ info: CustomerInfo) -> Bool {
        info.entitlements[PurchasesConfig.premiumEntitlementID]?.isActive == true
    }
}
#endif
