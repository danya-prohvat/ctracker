import Foundation

/// RevenueCat adapter for `PurchaseService` (spec §9).
///
/// The entire implementation is compiled out until the RevenueCat SDK is
/// present. To activate real billing:
///  1. In Xcode: File ▸ Add Package Dependencies…
///     https://github.com/RevenueCat/purchases-ios (add the "RevenueCat"
///     library product to the CalorieTracker target).
///  2. Paste the app's *public* SDK key ("appl_…") into
///     `PurchasesConfig.revenueCatAPIKey` below.
///  3. In the RevenueCat dashboard create ONE entitlement (id =
///     `PurchasesConfig.premiumEntitlementID`) attached to all four products —
///     weekly / monthly / yearly auto-renewable subscriptions plus the Lifetime
///     non-consumable — and a current Offering with the standard
///     weekly / monthly / annual / lifetime packages.
/// `PurchaseServices.make` then picks this service automatically — plan names
/// and prices on the paywall come from the store (`quotes()`), and purchases
/// unlock the "premium" entitlement mirrored into `UserSettings.isPremium`.

/// Build-time billing configuration. Lives outside the `#if canImport` block so
/// the key can be filled in before the package is added.
enum PurchasesConfig {
    /// RevenueCat public API key ("appl_…"). Empty string = billing not wired;
    /// keep using `StubPurchaseService`.
    static let revenueCatAPIKey = "appl_PwdrifgGiobkwIzsqYlpexrnOrL"

    /// The single entitlement every plan unlocks (identifier as configured in
    /// the RevenueCat dashboard).
    static let premiumEntitlementID = "Calorie Tracker Pro"
}

#if canImport(RevenueCat)
import RevenueCat

enum RevenueCatPurchaseError: LocalizedError {
    case notConfigured
    case noCurrentOffering
    case packageUnavailable

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Purchases are not configured."
        case .noCurrentOffering: return "No offering is available right now."
        case .packageUnavailable: return "This plan is currently unavailable."
        }
    }
}

/// Drop-in replacement for `StubPurchaseService`. Inject the live SwiftData
/// `UserSettings` singleton; the RevenueCat "premium" entitlement state is
/// mirrored into `settings.isPremium`, which the rest of the app reads through
/// `PremiumGate`.
final class RevenueCatPurchaseService: PurchaseService {
    private let settings: UserSettings

    init(settings: UserSettings) {
        self.settings = settings
        if !Purchases.isConfigured, !PurchasesConfig.revenueCatAPIKey.isEmpty {
            Purchases.configure(withAPIKey: PurchasesConfig.revenueCatAPIKey)
        }
    }

    func purchase(_ plan: PaywallPlan) async throws {
        guard Purchases.isConfigured else { throw RevenueCatPurchaseError.notConfigured }
        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.current else {
            throw RevenueCatPurchaseError.noCurrentOffering
        }
        guard let package = package(for: plan, in: offering) else {
            throw RevenueCatPurchaseError.packageUnavailable
        }
        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled { throw CancellationError() }
        apply(result.customerInfo)
    }

    func restore() async throws {
        guard Purchases.isConfigured else { throw RevenueCatPurchaseError.notConfigured }
        let info = try await Purchases.shared.restorePurchases()
        apply(info)
    }

    /// Localized product names/prices from the current Offering. Any failure →
    /// empty dictionary; the paywall then shows "—" instead of prices.
    func quotes() async -> [PaywallPlan: PaywallPlanQuote] {
        guard Purchases.isConfigured,
              let offering = try? await Purchases.shared.offerings().current
        else { return [:] }
        var quotes: [PaywallPlan: PaywallPlanQuote] = [:]
        for plan in PaywallPlan.allCases {
            guard let product = package(for: plan, in: offering)?.storeProduct else { continue }
            quotes[plan] = PaywallPlanQuote(
                title: product.localizedTitle.isEmpty ? nil : product.localizedTitle,
                price: product.localizedPriceString,
                pricePerMonth: plan == .yearly ? pricePerMonth(of: product) : nil
            )
        }
        return quotes
    }

    private func pricePerMonth(of product: StoreProduct) -> String? {
        guard let perMonth = product.pricePerMonth else { return nil }
        return product.priceFormatter?.string(from: perMonth)
    }

    private func package(for plan: PaywallPlan, in offering: Offering) -> Package? {
        switch plan {
        case .weekly: return offering.weekly
        case .monthly: return offering.monthly
        case .yearly: return offering.annual
        case .lifetime: return offering.lifetime
        }
    }

    private func apply(_ info: CustomerInfo) {
        settings.isPremium =
            info.entitlements[PurchasesConfig.premiumEntitlementID]?.isActive == true
    }
}
#endif
