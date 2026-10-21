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
/// unlock the premium entitlement mirrored into `UserSettings.isPremium`.

/// Build-time billing configuration. Lives outside the `#if canImport` block so
/// the key can be filled in before the package is added.
enum PurchasesConfig {
    /// RevenueCat public API key ("appl_…"). Empty string = billing not wired;
    /// keep using `StubPurchaseService`.
    static let revenueCatAPIKey = "appl_PwdrifgGiobkwIzsqYlpexrnOrL"

    /// The single entitlement every plan unlocks. Must match the entitlement
    /// *identifier* in the RevenueCat dashboard character for character
    /// (verified 2026-09-29 against `/v1/product_entitlement_mapping`; the old
    /// value "pro" matched nothing, so purchases never unlocked premium).
    static let premiumEntitlementID = "Calorie Tracker Pro"
}

#if canImport(RevenueCat)
import RevenueCat
import StoreKit

enum RevenueCatPurchaseError: LocalizedError {
    case notConfigured
    case noCurrentOffering
    case packageUnavailable

    var errorDescription: String? {
        switch self {
        case .notConfigured: return String(localized: "Purchases are not configured.", bundle: AppLanguage.current)
        case .noCurrentOffering: return String(localized: "No offering is available right now.", bundle: AppLanguage.current)
        case .packageUnavailable: return String(localized: "This plan is currently unavailable.", bundle: AppLanguage.current)
        }
    }
}

/// Drop-in replacement for `StubPurchaseService`. Inject the live SwiftData
/// `UserSettings` singleton; the RevenueCat "premium" entitlement state is
/// mirrored into `settings.isPremium`, which the rest of the app reads through
/// `PremiumGate`. Every verdict goes through `reconcile` (see the Reconcile
/// extension), and every backend call first binds the SDK to the iCloud user
/// (`RevenueCatIdentity`) so purchases land on an identity shared by all the
/// user's devices.
@MainActor
final class RevenueCatPurchaseService: PurchaseService {
    /// Not private: the Reconcile extension lives in its own file.
    let settings: UserSettings

    init(settings: UserSettings) {
        self.settings = settings
        // Normally already done in `CalorieTrackerApp.init()`; kept as a net.
        PurchasesBootstrap.configureIfNeeded()
    }

    func purchase(_ plan: PaywallPlan) async throws {
        guard Purchases.isConfigured else { throw RevenueCatPurchaseError.notConfigured }
        await RevenueCatIdentity.identifyIfNeeded()
        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.current else {
            throw RevenueCatPurchaseError.noCurrentOffering
        }
        guard let package = package(for: plan, in: offering) else {
            throw RevenueCatPurchaseError.packageUnavailable
        }
        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled { throw CancellationError() }
        // Paid but nothing unlocked = the dashboard entitlement doesn't match
        // `premiumEntitlementID` (or the product isn't attached to it). Fail
        // loudly instead of closing the paywall as if it had worked.
        guard isEntitled(result.customerInfo) else {
            throw RevenueCatPurchaseError.notConfigured
        }
        apply(true)
    }

    func restore() async throws {
        guard Purchases.isConfigured else { throw RevenueCatPurchaseError.notConfigured }
        await RevenueCatIdentity.identifyIfNeeded()
        // The SDK restores from StoreKit's *local* transaction cache, which is
        // empty right after a reinstall or an App Store account switch — the
        // user would get "Nothing to restore" for a subscription they own.
        // `AppStore.sync()` pulls the account's history first; it may show the
        // App Store sign-in sheet, legitimate here because the user tapped
        // Restore. Backing out of that sheet is a cancellation, not an error.
        do {
            try await AppStore.sync()
        } catch StoreKitError.userCancelled {
            throw CancellationError()
        }
        let info = try await Purchases.shared.restorePurchases()
        await reconcile(info)
    }

    func syncEntitlement() async {
        // `.fetchCurrent`, not the default cache-first policy: the SDK judges
        // a cached entitlement against the time it was fetched (3-day grace),
        // so the cache keeps answering "active" after the subscription has
        // expired and the fresh verdict only landed one activation later.
        // A throw (offline) means no verdict — `isPremium` stays as-is.
        guard Purchases.isConfigured else { return }
        await RevenueCatIdentity.identifyIfNeeded()
        guard let info = try? await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        else { return }
        await reconcile(info)
    }

    /// Runs for the life of the caller's task. Each update is reconciled and
    /// the settings' own context saved, so the caller needs no hook.
    func observeEntitlement() async {
        guard Purchases.isConfigured else { return }
        await RevenueCatIdentity.identifyIfNeeded()
        for await info in Purchases.shared.customerInfoStream {
            await reconcile(info)
            try? settings.modelContext?.save()
        }
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
                pricePerMonth: plan == .yearly ? pricePerMonth(of: product) : nil,
                trialDays: await eligibleTrialDays(of: product)
            )
        }
        return quotes
    }

    /// Days of the product's free-trial introductory offer, only while this
    /// user is still eligible (the store says "ineligible" once a trial was
    /// used on the account; "unknown" — offline — promises nothing).
    private func eligibleTrialDays(of product: StoreProduct) async -> Int? {
        guard let offer = product.introductoryDiscount, offer.paymentMode == .freeTrial
        else { return nil }
        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(
            productIdentifiers: [product.productIdentifier]
        )
        guard eligibility[product.productIdentifier]?.status == .eligible else { return nil }
        let period = offer.subscriptionPeriod
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        }
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
}
#endif
