import StoreKit

/// Answers "does this device hold an auto-renewable subscription right now?"
/// straight from StoreKit 2, independent of RevenueCat and of the Bool mirror
/// in `UserSettings.isPremium` (which cannot tell a Lifetime purchase, a
/// subscription and a DEBUG toggle apart). Used to decide whether the
/// "Manage subscription" row makes sense: StoreKit's manage-subscriptions
/// sheet is empty for a non-consumable Lifetime purchase and for a premium
/// flag with no transaction behind it.
///
/// No stored state and no @Model fields — the StoreKit entitlement cache is
/// the source of truth, so a schema change (and a CloudKit redeploy) is not
/// needed.
enum ActiveSubscriptionProbe {
    /// `true` when at least one verified, non-revoked current entitlement is
    /// an auto-renewable subscription. Lifetime non-consumable only → `false`;
    /// no transactions at all → `false`. Never throws: an unreadable store
    /// simply reads as "no subscription".
    static func hasAutoRenewableEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            if transaction.productType == .autoRenewable {
                return true
            }
        }
        return false
    }
}
