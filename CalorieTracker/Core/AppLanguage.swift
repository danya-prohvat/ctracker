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
    /// scheduling time. `nil` or unknown code → `.main` (process language).
    static func bundle(for code: String?) -> Bundle {
        guard let code,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }

    static func isRTL(_ code: String) -> Bool {
        Locale.Language(identifier: code).characterDirection == .rightToLeft
    }
}

extension View {
    /// Applies the stored language override immediately; no-op for System.
    @ViewBuilder
    func appLanguage(_ code: String?) -> some View {
        if let code {
            self
                .environment(\.locale, Locale(identifier: code))
                .environment(\.layoutDirection, AppLanguage.isRTL(code) ? .rightToLeft : .leftToRight)
        } else {
            self
        }
    }
}
