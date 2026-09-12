import SwiftUI

/// How a logged calendar day compares to the calorie target, driving the
/// month-grid ring color, its fill and the legend. Three deliberately
/// neutral-to-amber states: under-eating is styled as neither success nor
/// failure (a low number usually means incomplete logging), and over-eating
/// is amber, never red. This neutral palette is for retrospective surfaces
/// (calendar grid, period stats); the in-progress Today rings keep their
/// accent colors and reuse only the `over` threshold via `TodayRingStyle`
/// (user decision 2026-07-21).
enum CalendarRingState {
    /// Below `underThreshold` of target, or no target set — muted neutral gray.
    case under
    /// Within `[underThreshold, overThreshold]` of target — brand green.
    case onTarget
    /// Above `overThreshold` of target — amber.
    case over

    /// Consumed / target ratio boundaries. Single source of truth — never
    /// inline these fractions in views.
    static let underThreshold = 0.80
    static let overThreshold = 1.05

    /// Classifies a day's consumed calories against its target. A missing or
    /// non-positive target yields `.under` (no green/amber judgment without a
    /// target).
    init(consumed: Double, target: Double?) {
        guard let target, target > 0 else { self = .under; return }
        let ratio = consumed / target
        if ratio > Self.overThreshold {
            self = .over
        } else if ratio >= Self.underThreshold {
            self = .onTarget
        } else {
            self = .under
        }
    }

    var color: Color {
        switch self {
        case .under: Theme.calendarRingUnder
        case .onTarget: Theme.calendarRingOnTarget
        case .over: Theme.warning
        }
    }

    /// Localized state word, reused by the legend and the VoiceOver day label.
    var name: String {
        switch self {
        case .under: String(localized: "under", bundle: AppLanguage.current)
        case .onTarget: String(localized: "on target", bundle: AppLanguage.current)
        case .over: String(localized: "over", bundle: AppLanguage.current)
        }
    }
}
