import SwiftUI

/// Light/dark preference (user decision 2026-11-11): Settings → General →
/// Appearance offers System / Light / Dark; `.system` (the default) follows
/// the device. Applied once, at the root (`RootView.preferredColorScheme`),
/// where nil means "follow the system" — the palette itself adapts through
/// the light/dark pairs in `Theme`.
///
/// Stored in UserDefaults, deliberately not in `UserSettings`: like
/// `ads.firstLaunchAt` and the review-prompt state it is a per-device choice,
/// and a new @Model field would mean another CloudKit schema redeploy.
/// Read and written through `@AppStorage(AppAppearance.storageKey)` so the
/// Settings row and the root view share one live value.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    static let storageKey = "appearance.mode"

    var id: String { rawValue }

    /// nil = follow the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// Current stored choice, for code without an `@AppStorage` binding.
    static var current: AppAppearance {
        UserDefaults.standard.string(forKey: storageKey)
            .flatMap(AppAppearance.init(rawValue:)) ?? .system
    }
}
