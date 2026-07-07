import SwiftUI

/// User unit-system preference. Only changes the *default input unit* when logging;
/// stored nutrition is always per 100 g / 100 ml (spec §3).
enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case metric
    case us

    var id: String { rawValue }
    var label: LocalizedStringKey { self == .metric ? "Metric · g, ml" : "US · oz, fl oz" }

    /// Default input unit for a given basis under this system.
    func defaultUnit(for basis: Basis) -> FoodUnit {
        switch (self, basis.isVolume) {
        case (.metric, false): return .g
        case (.metric, true): return .ml
        case (.us, false): return .oz
        case (.us, true): return .floz
        }
    }
}
