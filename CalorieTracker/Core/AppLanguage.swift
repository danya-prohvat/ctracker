import SwiftUI

/// In-app language override (Settings → General → Language).
///
/// The picker stores the choice in `UserSettings.languageCode` and writes
/// `AppleLanguages`, which re-languages the whole process on the NEXT launch
/// (`String(localized:)`, notification texts, `Locale.current`). For the
/// current session `appLanguage(_:)` pushes the locale and layout direction
/// into the SwiftUI environment, so every `Text` switches immediately.
enum AppLanguage {
    /// True while non-view strings still run in the language the process was
    /// launched with — the settings row shows the restart footnote until then.
    static func needsRestart(chosen: String?) -> Bool {
        guard let chosen else { return false }
        return Bundle.main.preferredLocalizations.first != chosen
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
