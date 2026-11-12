import SwiftUI
import UIKit

/// Hex color helpers behind `Theme`. Every palette entry is a light/dark pair
/// resolved by the current color scheme (dark theme, user decision 2026-11-11),
/// so views never read `colorScheme` themselves — the adaptation lives here.
extension Color {
    /// Light-only color (scanner palette, which is dark on both schemes).
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    /// Light/dark pair. `darkAlpha` defaults to `alpha` so opaque colors need
    /// only the two hex values; translucent fills can pick a stronger dark alpha.
    init(light: UInt, dark: UInt, alpha: Double = 1, darkAlpha: Double? = nil) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkAlpha ?? alpha)
                : UIColor(hex: light, alpha: alpha)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt, alpha: Double) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: CGFloat(alpha)
        )
    }
}
