import Foundation

/// Abstraction over the billing backend (spec §9). The production backend is
/// RevenueCat (`RevenueCatPurchaseService`); the stub keeps the paywall working
/// in builds without the SDK. All four `PaywallPlan`s unlock the single
/// "premium" entitlement: weekly / monthly / yearly are auto-renewable
/// subscriptions, Lifetime is a non-consumable one-time purchase.
protocol PurchaseService {
    /// Buys the given plan. On success the injected `UserSettings.isPremium`
    /// reflects the new entitlement.
    func purchase(_ plan: PaywallPlan) async throws

    /// Restores previous purchases and re-applies the entitlement to
    /// `UserSettings.isPremium`.
    func restore() async throws

    /// Re-reads the entitlement from the billing backend and mirrors it into
    /// `UserSettings.isPremium` — the only path that ever *revokes* premium
    /// (expiry, cancellation, refund). Must leave the flag untouched when the
    /// backend can't answer: an offline launch never strips premium.
    func syncEntitlement() async

    /// Localized store display data (product name, price) per plan. Empty when
    /// the store is unreachable or billing isn't wired — the paywall then shows
    /// "—" instead of a price (prices are never hardcoded).
    func quotes() async -> [PaywallPlan: PaywallPlanQuote]
}

/// The single place that picks the billing backend: RevenueCat when the SDK is
/// compiled in and `PurchasesConfig.revenueCatAPIKey` is set, the development
/// stub otherwise.
enum PurchaseServices {
    static func make(settings: UserSettings) -> PurchaseService {
        #if canImport(RevenueCat)
        if !PurchasesConfig.revenueCatAPIKey.isEmpty {
            return RevenueCatPurchaseService(settings: settings)
        }
        #endif
        return StubPurchaseService(settings: settings)
    }
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
        try await Task.sleep(nanoseconds: 800_000_000)
        PremiumGate.applyEntitlement(true, settings: settings)
    }

    func restore() async throws {
        try await Task.sleep(nanoseconds: 800_000_000)
        PremiumGate.applyEntitlement(true, settings: settings)
    }

    // No backend to ask — whatever the debug toggle / stub purchase set stands.
    func syncEntitlement() async {}

    func quotes() async -> [PaywallPlan: PaywallPlanQuote] { [:] }
}
