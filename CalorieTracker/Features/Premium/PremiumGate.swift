import Foundation

/// Features gated behind the premium purchase (spec §9).
enum PremiumFeature {
    /// The full micronutrient catalog beyond the free set — prefer
    /// `PremiumGate.isNutrientUnlocked(_:settings:)` for per-nutrient checks.
    case nutrients
    /// Barcode scanner — see `PremiumGate.scanAllowance`.
    case scanner
    /// Calendar days older than the last 30 days.
    case deepHistory
}

/// Where a user stands with barcode scanning (user decision 2026-09-28).
enum ScanAllowance: Equatable {
    /// Premium: no counters, no ads.
    case unlimited
    /// Inside the welcome pool of `PremiumGate.freeScanLimit` scans.
    case welcome(left: Int)
    /// Pool spent: `PremiumGate.dailyFreeScanLimit` scans per local day,
    /// each behind the opt-in rewarded ad.
    case daily(left: Int)

    /// Scans still allowed; nil = unlimited.
    var scansLeft: Int? {
        switch self {
        case .unlimited: return nil
        case .welcome(let left), .daily(let left): return left
        }
    }
}

/// Single source of truth for what the current user may access (spec §9).
enum PremiumGate {
    /// Welcome pool: successful barcode scans a free user gets before the
    /// daily quota kicks in (user decision 2026-08-03: 10, was 3; only scans
    /// that found a product count — see `AddFoodScanFlow`).
    static let freeScanLimit = 10
    /// Successful scans a free user gets per local day once the pool is spent
    /// (user decision 2026-09-28: the scanner never goes dead for good — a
    /// scan costs an ad instead). Resets with the local day key.
    static let dailyFreeScanLimit = 3

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
        case .scanner: return (scanAllowance(settings: settings).scansLeft ?? 1) > 0
        case .deepHistory: return false
        }
    }

    /// The welcome pool is spent first; after it the per-day counter applies,
    /// read as zero whenever its day key is not today.
    static func scanAllowance(settings: UserSettings) -> ScanAllowance {
        if settings.isPremium { return .unlimited }
        let poolLeft = freeScanLimit - settings.scanCount
        if poolLeft > 0 { return .welcome(left: poolLeft) }
        let usedToday = settings.dailyScanDayKey == DayKey.today ? settings.dailyScanCount : 0
        return .daily(left: max(0, dailyFreeScanLimit - usedToday))
    }

    /// The single writer of the scan counters — one call per successful OFF
    /// lookup (`AddFoodScanFlow`). Premium never counts; the pool is spent
    /// before the day counter, which restarts on its first scan of a new day.
    static func recordSuccessfulScan(settings: UserSettings) {
        switch scanAllowance(settings: settings) {
        case .unlimited:
            return
        case .welcome:
            settings.scanCount += 1
        case .daily:
            if settings.dailyScanDayKey != DayKey.today {
                settings.dailyScanDayKey = DayKey.today
                settings.dailyScanCount = 0
            }
            settings.dailyScanCount += 1
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
