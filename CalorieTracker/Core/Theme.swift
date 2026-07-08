import SwiftUI

/// App palette: the prototype's green accent family over a native iOS
/// (Health-style) neutral base — flat grouped background and plain white cards.
enum Theme {
    // Flat light-gray base, matches systemGroupedBackground (light).
    static let background = Color(hex: 0xF2F2F7)
    static let card = Color.white

    // Greens (hue 156 family from the prototype).
    static let accent = Color(hex: 0x43A26D)          // rings, toggles — oklch(0.64 0.12 156)
    static let accentStrong = Color(hex: 0x39A36A)    // CTA buttons — oklch(0.64 0.13 156)
    static let accentLabel = Color(hex: 0x359561)     // links, nav actions — oklch(0.6 0.12 156)
    static let accentIcon = Color(hex: 0x0D8750)      // small icons — oklch(0.55 0.13 156)
    static let accentDeep = Color(hex: 0x28744A)      // text on soft green — oklch(0.5 0.1 156)
    static let accentSoft = Color(hex: 0xDFF5E6)      // soft green chips — oklch(0.95 0.03 156)
    static let accentSoftAlt = Color(hex: 0xDAF7E3)   // icon circles — oklch(0.95 0.04 156)

    // Text.
    static let textPrimary = Color(hex: 0x1C1C1E)
    static let textStrong = Color(hex: 0x3A3A3E)      // macro labels
    static let textSecondary = Color(hex: 0x8E8E93)
    static let textTertiary = Color(hex: 0xA0A0A5)
    static let textQuaternary = Color(hex: 0xB0B0B5)  // "kcal" captions
    static let chevron = Color(hex: 0xC4C4C9)

    // Fills.
    static let ringTrack = Color(hex: 0xECECED)
    static let separator = Color(hex: 0x3C3C43).opacity(0.07)
    static let controlFill = Color(hex: 0x787880).opacity(0.16)  // search field, segmented
    static let stepperFill = Color(hex: 0xF0F0F2)                // "−" stepper circles
    static let toggleOff = Color(hex: 0xD8D8DC)
    static let destructive = Color(hex: 0xFF3B30)
    static let destructiveSoft = Color(hex: 0xFFE0DA)            // trash button bg

    // Macro accent colors (protein / fat / carbs) + micronutrient bars.
    static let protein = Color(hex: 0xC36E63)         // oklch(0.63 0.11 28)
    static let fat = Color(hex: 0xC99B5A)             // oklch(0.72 0.1 75)
    static let carbs = Color(hex: 0x558CB9)           // oklch(0.62 0.09 245)
    static let microBar = Color(hex: 0x57A6B4)        // oklch(0.68 0.08 210)

    // Floating add button gradient.
    static let fabTop = Color(hex: 0x5CC388)          // oklch(0.74 0.13 156)
    static let fabBottom = Color(hex: 0x15985B)       // oklch(0.6 0.14 156)
    static let fabShadow = Color(hex: 0x14653D)       // oklch(0.45 0.1 156)

    // Calendar day rings.
    static let calendarRingToday = Color(hex: 0x39A36A)
    static let calendarRingPast = Color(hex: 0x93C5A5) // oklch(0.78 0.07 156)
    static let calendarDayMuted = Color(hex: 0xC4C4C9)

    // Barcode scanner (dark screen).
    static let scanBackground = Color(hex: 0x0E100F)
    static let scanCorner = Color(hex: 0x44B879)      // oklch(0.7 0.14 156)
    static let scanLine = Color(hex: 0x3FC07C)        // oklch(0.72 0.15 156)

    // Empty-state plate icon.
    static let emptyCircleFill = Color(hex: 0xE8F6EC) // oklch(0.96 0.02 156)
    static let emptyCircleRing = Color(hex: 0x7EBF96) // oklch(0.75 0.09 156)

    // Corner radii from the prototype.
    static let cornerRadius: CGFloat = 14             // settings rows, list cards
    static let radiusCard: CGFloat = 22               // summary / logged cards
    static let radiusControl: CGFloat = 12            // search field, segmented
    static let radiusButton: CGFloat = 14             // CTA buttons, keypad keys

    static let cardShadow = Color.black.opacity(0.04)
}

extension Font {
    /// SF Rounded numerals for stat values (calories, macros) — the
    /// Health/Fitness treatment. Text styles keep Dynamic Type scaling.
    static func stat(_ style: Font.TextStyle, _ weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
