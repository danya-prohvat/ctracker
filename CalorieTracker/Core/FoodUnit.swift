import Foundation

/// Input/display units. Canonical storage is always g / ml (spec §3).
enum FoodUnit: String, Codable, CaseIterable, Identifiable {
    case g
    case oz
    case ml
    case floz

    var id: String { rawValue }
    var isVolume: Bool { self == .ml || self == .floz }

    /// Multiplier to convert one unit into the canonical unit (g or ml).
    var toCanonical: Double {
        switch self {
        case .g: return 1
        case .oz: return 28.3495
        case .ml: return 1
        case .floz: return 29.5735
        }
    }

    /// Display label. Localized — some scripts write unit symbols in their own
    /// letters (e.g. Arabic); the enum raw values stay the stable storage keys.
    var label: String {
        switch self {
        case .g: return String(localized: "g", comment: "Unit symbol: grams")
        case .oz: return String(localized: "oz", comment: "Unit symbol: ounces")
        case .ml: return String(localized: "ml", comment: "Unit symbol: milliliters")
        case .floz: return String(localized: "fl oz", comment: "Unit symbol: fluid ounces")
        }
    }
}
