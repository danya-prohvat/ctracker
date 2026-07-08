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

    private var unitSystemRaw: String = UnitSystem.metric.rawValue
    /// nil = follow system language.
    var languageCode: String? = nil

    var netCarbsEnabled: Bool = false
    var notificationsEnabled: Bool = false
    /// Meal reminder times as minutes from midnight (local time).
    var reminderTimesMinutes: [Int] = []
    var iCloudSyncEnabled: Bool = false

    /// Barcode scans used by a free user (3 free, then paywall — spec §9).
    var scanCount: Int = 0

    var onboardingCompleted: Bool = false
    /// Resume point if onboarding is interrupted (spec §8).
    var onboardingStep: Int = 0

    /// Local premium override for development until RevenueCat is wired (spec §9).
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
    static func current(in context: ModelContext) -> UserSettings {
        var descriptor = FetchDescriptor<UserSettings>()
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = UserSettings()
        context.insert(created)
        return created
    }
}
