import Foundation
import SwiftData

/// Singleton of user preferences & daily goals (spec §1, §5). Fetched-or-created
/// via `UserSettings.current(in:)`.
@Model
final class UserSettings {
    var id: UUID = UUID()

    // Daily goals. nil = not set → show consumed without a progress indicator (spec §2.5).
    var calorieGoal: Double? = 2000
    var proteinGoal: Double? = 150
    var fatGoal: Double? = 67
    var carbGoal: Double? = 200

    /// Enabled micronutrient ids. Default: the free set — fiber, sugar,
    /// sodium, saturated fat.
    var enabledNutrients: [String] = Array(NutrientCatalog.defaultEnabled)
    /// Per-nutrient goal overrides (id → value). Missing → NutrientDef.defaultDV.
    var nutrientGoalOverrides: [String: Double] = [:]
    /// Frozen history of when the tracked-nutrient set changed — one entry per day
    /// it changed (see `NutrientTrackingChange`). Empty on legacy installs, where
    /// callers fall back to `enabledNutrients`. Lets a past day show the nutrients
    /// tracked *then*, so changing the set later never rewrites history (spec §2.1).
    var nutrientTrackingLog: [NutrientTrackingChange] = []

    private var unitSystemRaw: String = UnitSystem.metric.rawValue
    /// nil = follow system language.
    var languageCode: String? = nil

    var netCarbsEnabled: Bool = false
    /// The single reminders toggle (user decision 2026-07-21): covers both the
    /// smart meal reminders (`MealReminderScheduler`) and the re-engagement
    /// series (`ReengagementNotificationService`).
    var notificationsEnabled: Bool = false
    /// ON by default (user decision 2026-09-12) — free feature, silent local
    /// fallback when the iCloud account is unavailable.
    var iCloudSyncEnabled: Bool = true

    /// Successful OFF-lookup scans used by a free user (10 free, then paywall —
    /// user decision 2026-08-03; local re-scans and not-found don't count).
    var scanCount: Int = 0

    var onboardingCompleted: Bool = false
    /// Resume point if onboarding is interrupted (spec §8).
    var onboardingStep: Int = 0

    /// Local mirror of the RevenueCat "pro" entitlement, kept in sync by
    /// `PurchaseService.syncEntitlement()` on every scene activation. The rest
    /// of the app reads it only through `PremiumGate`.
    var isPremium: Bool = false

    var unitSystem: UnitSystem {
        get { UnitSystem(rawValue: unitSystemRaw) ?? .metric }
        set { unitSystemRaw = newValue.rawValue }
    }

    init() {}
}

extension UserSettings {
    func isEnabled(_ nutrientID: String) -> Bool { enabledNutrients.contains(nutrientID) }

    /// Enabled nutrient defs in catalog order.
    var enabledNutrientDefs: [NutrientDef] {
        NutrientCatalog.all.filter { enabledNutrients.contains($0.id) }
    }

    /// Effective daily goal for a nutrient (override, else catalog default).
    func goal(for nutrientID: String) -> Double? {
        if let override = nutrientGoalOverrides[nutrientID] { return override }
        return NutrientCatalog.def(nutrientID)?.defaultDV
    }

    /// Fetch the singleton settings, creating it on first launch.
    ///
    /// CloudKit merges can leave two "singletons" (cloud stores allow no
    /// unique constraints): two devices that first launched offline each
    /// created one. Every device keeps the same deterministic winner (see
    /// `mergePriority`) and deletes the rest, so they converge.
    static func current(in context: ModelContext) -> UserSettings {
        let all = (try? context.fetch(FetchDescriptor<UserSettings>())) ?? []
        if let winner = all.min(by: mergePriority) {
            if all.count > 1 {
                for extra in all where extra !== winner { context.delete(extra) }
                try? context.save()
            }
            return winner
        }
        let created = UserSettings()
        created.unitSystem = defaultUnitSystem
        context.insert(created)
        return created
    }

    /// First-launch default: follow the device's measurement system (user
    /// decision 2026-07-21). `.uk` counts as metric — food there is labeled
    /// in g/ml. Also the reset target for "Delete all data".
    static var defaultUnitSystem: UnitSystem {
        Locale.current.measurementSystem == .us ? .us : .metric
    }

    /// Deterministic post-merge winner: prefer the instance with real
    /// accumulated state — finished onboarding, then the longer
    /// nutrient-tracking log — so a fresh install's defaults never replace a
    /// long-time user's settings. UUID only breaks exact ties. Pure function
    /// of content → every device picks the same winner, no coordination.
    private static func mergePriority(_ a: UserSettings, _ b: UserSettings) -> Bool {
        if a.onboardingCompleted != b.onboardingCompleted { return a.onboardingCompleted }
        if a.nutrientTrackingLog.count != b.nutrientTrackingLog.count {
            return a.nutrientTrackingLog.count > b.nutrientTrackingLog.count
        }
        return a.id.uuidString < b.id.uuidString
    }
}
