import SwiftUI

/// App palette: the prototype's green accent family over a native iOS
/// (Health-style) neutral base — flat grouped background and plain cards.
/// Every entry is a light/dark pair (`Color(light:dark:)`, see AdaptiveColor):
/// the light values are the original palette, the dark ones follow the system
/// dark look — near-black base (not pure black, so the aurora washes read),
/// elevated gray cards, brighter accents for contrast. Views never branch on
/// `colorScheme`; adding a color here is the only way to adapt one.
enum Theme {
    // Neutral base under the aurora washes (see AppBackground) and cards.
    static let background = Color(light: 0xF5F6F5, dark: 0x121413)
    static let card = Color(light: 0xFFFFFF, dark: 0x1E201F)

    // Aurora backdrop washes — brand green, cool blue, warm amber at low
    // opacity over `background`. Echo the accent/macro palette but are
    // deliberately standalone so retuning macros never shifts the backdrop.
    // Dark: darker, less saturated, lower alpha — a glow, not a spotlight.
    static let auroraGreen = Color(light: 0x5CC388, dark: 0x3E9A68, alpha: 0.28, darkAlpha: 0.16)
    static let auroraBlue = Color(light: 0x558CB9, dark: 0x4A7FA8, alpha: 0.17, darkAlpha: 0.12)
    static let auroraWarm = Color(light: 0xC99B5A, dark: 0xB88A4F, alpha: 0.15, darkAlpha: 0.10)

    // Greens (hue 156 family from the prototype).
    static let accent = Color(light: 0x43A26D, dark: 0x4FB87C)        // rings, toggles
    static let accentStrong = Color(light: 0x39A36A, dark: 0x43B276)  // CTA buttons
    static let accentLabel = Color(light: 0x359561, dark: 0x5CC388)   // links, nav actions
    static let accentIcon = Color(light: 0x0D8750, dark: 0x4FBF82)    // small icons
    static let accentDeep = Color(light: 0x28744A, dark: 0x8FDDB0)    // text on soft green
    static let accentSoft = Color(light: 0xDFF5E6, dark: 0x1E3A2B)    // soft green chips
    static let accentSoftAlt = Color(light: 0xDAF7E3, dark: 0x213F2F) // icon circles
    static let accentChipBorder = Color(light: 0xB4D8C0, dark: 0x3F7A58, alpha: 0.6)
    static let barcodeGlyph = Color(light: 0x14653D, dark: 0x8FDDB0)  // SavedBarcodeChip bars

    // Text.
    static let textPrimary = Color(light: 0x1C1C1E, dark: 0xF2F2F7)
    static let textStrong = Color(light: 0x3A3A3E, dark: 0xD9D9DE)    // macro labels
    static let textSecondary = Color(light: 0x8E8E93, dark: 0x98989E)
    static let textTertiary = Color(light: 0xA0A0A5, dark: 0x7E7E84)
    static let textQuaternary = Color(light: 0xB0B0B5, dark: 0x6A6A70) // "kcal" captions
    static let textDim = Color(light: 0x6B6B70, dark: 0xA8A8AE)       // stepper "−", goal norms
    static let chevron = Color(light: 0xC4C4C9, dark: 0x5A5A60)

    // Fills.
    static let ringTrack = Color(light: 0xECECED, dark: 0x2E302F)
    static let barTrack = Color(light: 0x3C3C43, dark: 0xEBEBF5, alpha: 0.10, darkAlpha: 0.12)
    static let separator = Color(light: 0x3C3C43, dark: 0xEBEBF5, alpha: 0.07, darkAlpha: 0.10)
    static let controlFill = Color(light: 0x787880, dark: 0x787880, alpha: 0.16, darkAlpha: 0.24)
    static let segmentSelected = Color(light: 0xFFFFFF, dark: 0x636366) // mini g/ml segment
    static let stepperFill = Color(light: 0xF0F0F2, dark: 0x2C2E2D)   // "−" stepper circles
    static let toggleOff = Color(light: 0xD8D8DC, dark: 0x39393D)
    static let destructive = Color(light: 0xFF3B30, dark: 0xFF453A)
    static let warning = Color(light: 0xFF9500, dark: 0xFF9F0A)       // near-limit amber
    static let destructiveSoft = Color(light: 0xFFE0DA, dark: 0x4A2522) // trash button bg
    static let neutralAction = Color(light: 0x8E8E93, dark: 0x8E8E93) // gray swipe action (Edit)

    // Macro accent colors (protein / fat / carbs) + micronutrient bars.
    static let protein = Color(light: 0xC36E63, dark: 0xD67F74)
    static let fat = Color(light: 0xC99B5A, dark: 0xD9AC6B)
    static let carbs = Color(light: 0x558CB9, dark: 0x6DA2CF)
    static let microBar = Color(light: 0x57A6B4, dark: 0x68B9C7)

    // Floating add button gradient (saturated enough for both schemes).
    static let fabTop = Color(light: 0x5CC388, dark: 0x5CC388)
    static let fabBottom = Color(light: 0x15985B, dark: 0x15985B)
    static let fabShadow = Color(light: 0x14653D, dark: 0x14653D)

    // Calendar day rings — colored by the day's calories vs. calorie target.
    static let calendarRingOnTarget = Color(light: 0x39A36A, dark: 0x43B276) // 80–105%
    static let calendarRingUnder = Color(light: 0xC4C4C9, dark: 0x5A5A60)    // under / no target
    // Over 105% of target uses `warning` (amber). Empty days draw no ring.
    static let calendarRingTrack = Color(light: 0xEEEEF0, dark: 0x2E302F)
    static let calendarDayMuted = Color(light: 0xC4C4C9, dark: 0x5A5A60)

    // Settings row icon tiles (iOS Settings style, user decision 2026-11-12):
    // white SF Symbol on a filled rounded square. Hues echo the accent/macro
    // palette so Settings reads as one system with the rings; dark values are
    // a touch brighter, like the accents.
    static let tileGreen = Color(light: 0x43A26D, dark: 0x4FB87C)
    static let tileTeal = Color(light: 0x57A6B4, dark: 0x68B9C7)
    static let tileBlue = Color(light: 0x558CB9, dark: 0x6DA2CF)
    static let tileSlate = Color(light: 0x5B7FA6, dark: 0x7396BD)
    static let tileCoral = Color(light: 0xC36E63, dark: 0xD67F74)
    static let tileSand = Color(light: 0xC99B5A, dark: 0xD9AC6B)
    static let tileGray = Color(light: 0x8E8E93, dark: 0x98989E)
    static let tileRed = Color(light: 0xFF3B30, dark: 0xFF453A)
    // Goals & nutrients page: tint behind a tracked (switched-on) nutrient
    // row, and the soft amber behind the "Limit" badge.
    static let rowActiveFill = Color(light: 0xF4FAF6, dark: 0x232A26)
    static let warningSoft = Color(light: 0xFFF1DC, dark: 0x3F2F12)

    // Goals & nutrients page: one hue per catalog group for the soft
    // nutrient circles (user decision 2026-11-12). Distinct from the macro
    // palette and the Settings tiles so the four groups read at a glance.
    static let nutrientMacromineral = Color(light: 0x5B7FA6, dark: 0x7396BD)
    static let nutrientMicroelement = Color(light: 0x57A6B4, dark: 0x68B9C7)
    static let nutrientVitamin = Color(light: 0xE0955A, dark: 0xEBA66E)
    static let nutrientOther = Color(light: 0x9B7FB8, dark: 0xAD93C9)

    // Barcode scanner (dark screen on both schemes — not adaptive).
    static let scanBackground = Color(hex: 0x0E100F)
    static let scanCorner = Color(hex: 0x44B879)
    static let scanLine = Color(hex: 0x3FC07C)

    // Empty-state plate icon (green for Today, muted for past days).
    static let emptyCircleFill = Color(light: 0xE8F6EC, dark: 0x1E3A2B)
    static let emptyCircleRing = Color(light: 0x7EBF96, dark: 0x5CA47A)
    static let emptyCircleFillMuted = Color(light: 0xF4F4F6, dark: 0x2A2C2B)
    static let emptyCircleRingMuted = Color(light: 0xD0D0D5, dark: 0x5A5A60)

    // Corner radii from the prototype.
    static let cornerRadius: CGFloat = 14             // settings rows, list cards
    static let radiusCard: CGFloat = 22               // summary / logged cards
    static let radiusControl: CGFloat = 12            // search field, segmented
    static let radiusButton: CGFloat = 14             // CTA buttons, keypad keys

    // Card shadow: barely-there in light, off in dark (elevation comes from
    // the lighter card fill, as in system grouped lists).
    static let cardShadow = Color(light: 0x000000, dark: 0x000000, alpha: 0.04, darkAlpha: 0)
}

extension Font {
    /// SF Rounded numerals for stat values (calories, macros) — the
    /// Health/Fitness treatment. Text styles keep Dynamic Type scaling.
    static func stat(_ style: Font.TextStyle, _ weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}
