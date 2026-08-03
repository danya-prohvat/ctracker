import Foundation

/// Warm cache for the paywall's store quotes (user decision 2026-08-03):
/// RootView prefetches on scene activation, so by the time the user opens the
/// paywall the plan rows render real prices instantly instead of flashing
/// skeletons while the store round-trip finishes. The paywall still refreshes
/// quotes on every open — the cache only bridges the gap, and a fresh fetch
/// replaces it seconds later.
@MainActor
enum PaywallQuotesCache {
    private(set) static var cached: [PaywallPlan: PaywallPlanQuote]?
    private static var isFetching = false

    /// Fills a cold cache; no-op while a fetch is in flight or after quotes
    /// have arrived. A failed fetch (offline) retries on the next activation.
    static func prefetch(settings: UserSettings) async {
        guard cached == nil, !isFetching else { return }
        isFetching = true
        defer { isFetching = false }
        store(await PurchaseServices.make(settings: settings).quotes())
    }

    /// The paywall's loader: fresh quotes when the store responds, otherwise
    /// whatever the cache holds, otherwise empty (rows then show "—").
    static func load(settings: UserSettings) async -> [PaywallPlan: PaywallPlanQuote] {
        let fresh = await PurchaseServices.make(settings: settings).quotes()
        store(fresh)
        return fresh.isEmpty ? (cached ?? [:]) : fresh
    }

    private static func store(_ quotes: [PaywallPlan: PaywallPlanQuote]) {
        if !quotes.isEmpty { cached = quotes }
    }
}
