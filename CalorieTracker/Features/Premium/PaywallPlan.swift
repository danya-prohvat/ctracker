import SwiftUI

/// Purchase plans offered on the paywall (spec §9). Weekly / monthly / yearly
/// are auto-renewable subscriptions; lifetime is a one-time non-consumable.
/// No free trial anywhere.
enum PaywallPlan: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly
    case lifetime

    var id: String { rawValue }

    /// Fallback plan name, shown until the store provides a localized product
    /// title (see `PaywallPlanQuote.title`).
    var displayName: LocalizedStringKey {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }
}

/// Store-provided display data for one plan — localized product name and price
/// as returned by RevenueCat/StoreKit (`PurchaseService.quotes()`). Prices are
/// never hardcoded: until a quote arrives the paywall shows a skeleton, and a
/// plan missing from the store shows "—".
struct PaywallPlanQuote {
    /// Localized product name from App Store Connect; nil → `displayName`.
    var title: String?
    /// Localized price string, e.g. "$29.99".
    var price: String
    /// Per-month equivalent price (yearly plan only).
    var pricePerMonth: String?
}
