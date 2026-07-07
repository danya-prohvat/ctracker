import Foundation

/// Abstraction over the billing backend so the paywall could ship before real
/// billing is wired up (spec §9).
///
/// TODO(real billing): production implementation is RevenueCat — see
/// `RevenueCatPurchaseService.swift`. All four `PaywallPlan`s unlock a single
/// "premium" entitlement: weekly / monthly / yearly are auto-renewable
/// subscriptions, Lifetime is a non-consumable one-time purchase.
protocol PurchaseService {
    /// Buys the given plan. On success the injected `UserSettings.isPremium`
    /// reflects the new entitlement.
    func purchase(_ plan: PaywallPlan) async throws

    /// Restores previous purchases and re-applies the entitlement to
    /// `UserSettings.isPremium`.
    func restore() async throws
}

/// Development stub: pretends the App Store took 0.8 s, then unlocks premium.
///
/// Inject the live `UserSettings` instance — the SwiftData singleton obtained
/// via `UserSettings.current(in:)` (or the first result of a `@Query`). The
/// service mutates `isPremium` directly on that instance, so the caller only
/// needs to save the model context afterwards.
final class StubPurchaseService: PurchaseService {
    private let settings: UserSettings

    init(settings: UserSettings) {
        self.settings = settings
    }

    func purchase(_ plan: PaywallPlan) async throws {
        // TODO(RevenueCat): replace with Purchases.shared.purchase(package:),
        // mapping PaywallPlan → the weekly/monthly/annual/lifetime package of
        // the current Offering. One "premium" entitlement covers all plans.
        try await Task.sleep(nanoseconds: 800_000_000)
        settings.isPremium = true
    }

    func restore() async throws {
        // TODO(RevenueCat): replace with Purchases.shared.restorePurchases()
        // and mirror the "premium" entitlement into settings.isPremium.
        try await Task.sleep(nanoseconds: 800_000_000)
        settings.isPremium = true
    }
}
