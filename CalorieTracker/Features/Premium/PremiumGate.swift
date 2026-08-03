import Foundation

/// Features gated behind the premium purchase (spec §9).
enum PremiumFeature {
    /// The full micronutrient catalog beyond the free set — prefer
    /// `PremiumGate.isNutrientUnlocked(_:settings:)` for per-nutrient checks.
    case nutrients
    /// Barcode scanner. Free users get 10 successful scans, then the paywall.
    case scanner
    /// Calendar days older than the last 30 days.
    case deepHistory
}

/// Single source of truth for what the current user may access (spec §9).
enum PremiumGate {
    /// Successful barcode scans a free user gets before the scanner locks
    /// (user decision 2026-08-03: 10, was 3; only scans that found a product
    /// count — see `AddFoodScanFlow`).
    static let freeScanLimit = 10

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
        case .scanner: return settings.scanCount < freeScanLimit
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

    /// Barcode scans a free user still has left (0 when exhausted; irrelevant —
    /// but still counts down — for premium users, who never hit the limit).
    static func remainingFreeScans(settings: UserSettings) -> Int {
        max(0, freeScanLimit - settings.scanCount)
    }
}
