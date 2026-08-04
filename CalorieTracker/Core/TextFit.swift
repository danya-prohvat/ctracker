import SwiftUI

/// Fitting rules for text inside size-constrained controls, so long
/// localizations degrade gracefully instead of wrapping inside pills or
/// overflowing fixed-height CTAs.
extension View {
    /// Badge/capsule labels ("Upgrade", "BEST VALUE"): never wrap — the pill
    /// keeps one line and grows, neighboring flexible text wraps instead.
    func badgeFit() -> some View {
        self.lineLimit(1).fixedSize()
    }

    /// Fixed-height CTA and tab labels: stay on one line, shrinking slightly
    /// when a long localization (or large Dynamic Type) would otherwise wrap.
    func ctaFit() -> some View {
        self.lineLimit(1).minimumScaleFactor(0.75)
    }
}
