import Foundation

/// Features gated behind the premium purchase (spec §9).
enum PremiumFeature {
    /// The full micronutrient catalog. Fiber and sugar are always free — callers
    /// treat those two as unlocked themselves and consult this gate for the rest.
    case nutrients
    /// Barcode scanner. Free users get 3 scans, then the paywall.
    case scanner
    case icloudSync
    /// Calendar days older than the last 30 days.
    case deepHistory
}

/// Single source of truth for what the current user may access (spec §9).
enum PremiumGate {
    /// Barcode scans a free user gets before the scanner locks.
    static let freeScanLimit = 3

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
        case .icloudSync: return false
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
