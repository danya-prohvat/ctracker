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

    var label: String {
        switch self {
        case .g: return "g"
        case .oz: return "oz"
        case .ml: return "ml"
        case .floz: return "fl oz"
        }
    }

    /// Units available for a basis — weight products get g/oz, volume products ml/fl oz.
    /// Logging "ml of cheese" must be physically impossible (spec §3).
    static func units(for basis: Basis) -> [FoodUnit] {
        basis.isVolume ? [.ml, .floz] : [.g, .oz]
    }
}
