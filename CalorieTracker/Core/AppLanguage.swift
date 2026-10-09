import SwiftUI

/// In-app language override (Settings → General → Language).
///
/// The picker stores the choice in `UserSettings.languageCode` and writes
/// `AppleLanguages`, which re-languages the whole process on the NEXT launch
/// (`String(localized:)`, notification texts, `Locale.current`). For the
/// current session `appLanguage(_:)` pushes the locale and layout direction
/// into the SwiftUI environment, so every `Text` switches immediately.
enum AppLanguage {
    /// Bundle that serves `String(localized:)` lookups in the chosen language
    /// before the process itself restarts into it. Needed wherever strings are
    /// baked outside the SwiftUI environment — notification texts are built at
    /// scheduling time. Resolves the System case too, so picking System after
    /// an explicit language reschedules notifications in the device language.
    static func bundle(for code: String?) -> Bundle {
        guard let code = effectiveOverride(for: code),
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }

    /// Same bundle for `String(localized:)` call sites that cannot reach
    /// `UserSettings` (unit symbols, enum state names, purchase errors —
    /// values baked as `String`, which the SwiftUI environment locale does
    /// not re-resolve). Reads the app-domain `AppleLanguages` override that
    /// the language picker writes together with `settings.languageCode`, so
    /// the two never diverge; System (no override) resolves the stale-process
    /// case exactly like `effectiveOverride(nil)`.
    static var current: Bundle {
        bundle(for: pickedCode)
    }

    /// Locale for values formatted outside the SwiftUI environment — numbers
    /// (`Format`), date strings built with `.formatted()`, weekday symbols.
    /// `Locale.current` is frozen at process launch, so without this a month
    /// name or a grouping separator stayed in the previous language until
    /// restart (fix 2026-09-29). Same value `appLanguage(_:)` pushes into the
    /// environment, so baked strings and `Text` never disagree.
    static var locale: Locale {
        effectiveOverride(for: pickedCode).map(Locale.init(identifier:)) ?? .current
    }

    /// The language picker's choice as written to the app-domain
    /// `AppleLanguages` (nil = System). Mirrors `UserSettings.languageCode`
    /// for call sites without a model context — presentation roots use it to
    /// re-apply the override (see `presentationLanguage()`).
    static var pickedCode: String? {
        let appDomain = Bundle.main.bundleIdentifier
            .flatMap { UserDefaults.standard.persistentDomain(forName: $0) }
        return (appDomain?["AppleLanguages"] as? [String])?.first
    }

    static func isRTL(_ code: String) -> Bool {
        Locale.Language(identifier: code).characterDirection == .rightToLeft
    }

    /// The code to override the environment with. An explicit choice wins
    /// as-is; for System (`nil`) the device's true language is applied — but
    /// only while the process still runs in a different one (it was launched
    /// under a since-removed `AppleLanguages` override, which keeps serving
    /// old strings until relaunch — fix 2026-09-08: picking System used to be
    /// a silent no-op until restart). On a system-driven launch this returns
    /// `nil`, keeping the native no-override behavior (full region-aware locale).
    static func effectiveOverride(for code: String?) -> String? {
        if let code { return code }
        guard let system = systemLanguageCode,
              system != Bundle.main.preferredLocalizations.first else { return nil }
        return system
    }

    /// The device's preferred language among the app's localizations, read
    /// from the GLOBAL preferences domain — unlike `Locale.current`, this is
    /// not masked by the app's own `AppleLanguages` override and not frozen
    /// at process launch. `Bundle.preferredLocalizations` handles fallback
    /// matching ("en-UA" → "en").
    private static var systemLanguageCode: String? {
        guard let global = CFPreferencesCopyValue("AppleLanguages" as CFString,
                                                  kCFPreferencesAnyApplication,
                                                  kCFPreferencesCurrentUser,
                                                  kCFPreferencesAnyHost) as? [String],
              !global.isEmpty else { return nil }
        return Bundle.preferredLocalizations(from: Bundle.main.localizations,
                                             forPreferences: global).first
    }
}

/// Single-branch override: an `if/else` around `self` gave the two cases
/// different view identities, so System ↔ language flips rebuilt the whole
/// tree — state reset, animations cut (fix 2026-10-09). With no override the
/// inherited values are written back unchanged.
private struct AppLanguageModifier: ViewModifier {
    let code: String?
    @Environment(\.locale) private var inheritedLocale
    @Environment(\.layoutDirection) private var inheritedDirection

    func body(content: Content) -> some View {
        let override = AppLanguage.effectiveOverride(for: code)
        content
            .environment(\.locale, override.map(Locale.init(identifier:)) ?? inheritedLocale)
            .environment(\.layoutDirection, override.map(direction) ?? inheritedDirection)
    }

    private func direction(_ code: String) -> LayoutDirection {
        AppLanguage.isRTL(code) ? .rightToLeft : .leftToRight
    }
}

extension View {
    /// Applies the stored language override immediately. For System the
    /// device language is applied only when the process language is stale
    /// (see `AppLanguage.effectiveOverride`).
    func appLanguage(_ code: String?) -> some View {
        modifier(AppLanguageModifier(code: code))
    }

    /// Re-applies the override at the root of a sheet / full-screen cover.
    /// A presented hosting controller inherits the environment `locale`, but
    /// takes its `layoutDirection` from UIKit — i.e. the PROCESS language —
    /// so with Arabic picked in an English-launched app every modal came up
    /// LTR (and vice versa after a relaunch; fix 2026-10-09). Every
    /// `.sheet`/`.fullScreenCover` content must start with this.
    func presentationLanguage() -> some View {
        appLanguage(AppLanguage.pickedCode)
    }
}
