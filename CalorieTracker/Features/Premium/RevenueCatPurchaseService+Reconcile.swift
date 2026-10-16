import Foundation

#if canImport(RevenueCat)
import RevenueCat

/// Entitlement verdict → `UserSettings.isPremium`, shared by sync, restore and
/// the customer-info stream (fixed 2026-10-15).
extension RevenueCatPurchaseService {
    /// Serialises concurrent verdicts (activation sync + stream).
    private static var reconciling = false
    /// One "unbacked premium" strike per process (see `reconcile`).
    private static var struckThisLaunch = false
    private static let strikesKey = "premium.unbackedStrikes"

    /// Mirrors a verdict into the settings without ever touching the App
    /// Store on its own — nothing here may show the sign-in sheet.
    ///
    /// - Backend entitled → premium on.
    /// - Backend not entitled → ask StoreKit 2 whether this Apple Account
    ///   holds a verified, unrevoked entitlement for one of our products
    ///   (`StoreEntitlementProbe`, local cache, never prompts). It does →
    ///   premium on, verified by the device: the purchase may still sit on an
    ///   older anonymous backend user (a device that hasn't logged in yet) or
    ///   the backend may simply not have seen it after a reinstall; the
    ///   backend catches up on the next purchase or Restore tap. Automatic
    ///   `syncPurchases`/`restorePurchases` are deliberately NOT used here:
    ///   in StoreKit 2 mode both fetch `AppTransaction.shared`, which in
    ///   sandbox/TestFlight shows "Apple Account Sign-In Requested" on launch.
    /// - Neither side has it while the app says premium (CloudKit synced a
    ///   flag from another Apple ID, a DEBUG override, an expired plan) → a
    ///   strike. `Transaction.currentEntitlements` is also empty right after
    ///   a reinstall, before the StoreKit daemon has pulled the account's
    ///   history, or while signed out of the App Store, so one empty answer
    ///   never revokes: premium goes off (and the gate trims the tracked
    ///   nutrients forward) only on the second strike, counted at most once
    ///   per process. Any positive verdict clears the strikes.
    func reconcile(_ info: CustomerInfo) async {
        if isEntitled(info) {
            apply(true)
            Self.clearStrikes()
            return
        }
        guard !Self.reconciling else { return }
        Self.reconciling = true
        defer { Self.reconciling = false }
        if await StoreEntitlementProbe.hasAnyCurrentEntitlement() {
            apply(true)
            Self.clearStrikes()
            return
        }
        guard settings.isPremium, Self.strike() else { return }
        apply(false)
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

    /// Records one strike per process; true when this is the second strike.
    /// Per-device bookkeeping, deliberately in UserDefaults — never synced.
    private static func strike() -> Bool {
        let defaults = UserDefaults.standard
        if !struckThisLaunch {
            struckThisLaunch = true
            defaults.set(defaults.integer(forKey: strikesKey) + 1, forKey: strikesKey)
        }
        return defaults.integer(forKey: strikesKey) >= 2
    }

    private static func clearStrikes() {
        UserDefaults.standard.removeObject(forKey: strikesKey)
    }
}
#endif
