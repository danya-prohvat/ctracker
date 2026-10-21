import Foundation

/// Features gated behind the premium purchase (spec §9).
enum PremiumFeature {
    /// The full micronutrient catalog beyond the free set — prefer
    /// `PremiumGate.isNutrientUnlocked(_:settings:)` for per-nutrient checks.
    case nutrients
    /// Calendar days older than the last 30 days.
    case deepHistory
}

/// Single source of truth for what the current user may access (spec §9).
/// The barcode scanner is not gated here: it is unlimited for everyone, and
/// a free user's scans past the daily ad-free ones cost an opt-in rewarded ad
/// instead (user decision 2026-10-19, see `ScanRewardGate`).
enum PremiumGate {
    /// Nutrients every user gets for free — deliberately the same set as the
    /// first-launch defaults (fiber, sugar, sodium, saturated fat): one
    /// product decision, one source of truth.
    static let freeNutrientIDs: Set<String> = NutrientCatalog.defaultEnabled

    /// Per-nutrient gate: free-set nutrients are always available, the rest
    /// follow the premium `.nutrients` feature.
    static func isNutrientUnlocked(_ nutrientID: String, settings: UserSettings) -> Bool {
        freeNutrientIDs.contains(nutrientID) || isUnlocked(.nutrients, settings: settings)
    }

    /// Premium status for banners / bookkeeping. Views read this instead of
    /// touching `settings.isPremium` directly, so the gate stays the single
    /// access point (spec §9).
    static func isPremium(settings: UserSettings) -> Bool {
        settings.isPremium
    }

    static func isUnlocked(_ feature: PremiumFeature, settings: UserSettings) -> Bool {
        if settings.isPremium { return true }
        switch feature {
        case .nutrients: return false
        case .deepHistory: return false
        }
    }

    /// True when a diary day is viewable: premium, or the day falls within the
    /// last 30 days including today. Future days are never locked — deep history
    /// only gates the past. Comparison is lexicographic on "yyyy-MM-dd" keys,
    /// which matches chronological order.
    static func isDayUnlocked(dayKey: String, settings: UserSettings) -> Bool {
        if settings.isPremium { return true }
        guard let today = DayKey.date(from: DayKey.today),
              let cutoff = Calendar.current.date(byAdding: .day, value: -29, to: today)
        else { return false }
        return dayKey >= DayKey.string(from: cutoff)
    }

    /// The single writer of `settings.isPremium`: mirrors a definitive
    /// entitlement verdict (purchase, restore, sync, DEBUG override). On a true
    /// premium→free transition the tracked-nutrient set is trimmed forward to
    /// the free set (spec §2.1 forward rule) — never on a plain launch for a
    /// user who was already free. Callers with no verdict (offline fetch
    /// failed) must not call this at all.
    static func applyEntitlement(_ isPremium: Bool, settings: UserSettings) {
        let lostPremium = settings.isPremium && !isPremium
        settings.isPremium = isPremium
        if lostPremium { trimNutrientsToFreeSet(settings: settings) }
    }

    /// Intersect the current set with the free set through the tracking log
    /// (baseline first, then record — past days keep what they tracked then).
    /// Free nutrients the user had switched off stay off, and stored goal
    /// overrides for trimmed nutrients are kept for a future re-enable.
    private static func trimNutrientsToFreeSet(settings: UserSettings) {
        guard settings.enabledNutrients.contains(where: { !freeNutrientIDs.contains($0) })
        else { return }
        settings.ensureNutrientTrackingBaseline()
        settings.enabledNutrients.removeAll { !freeNutrientIDs.contains($0) }
        settings.recordNutrientTrackingChange()
    }
}
