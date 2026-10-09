import SwiftUI

extension View {
    /// Native collapsing large title for a tab-root screen: the big title pins
    /// to an inline nav bar on scroll (Health/Fitness behavior). Replaces the
    /// old hand-drawn headers. `subtitle` uses the iOS 26 `navigationSubtitle`
    /// when available and is a no-op below (keeps the iOS 17 target building).
    func largeTitleScreen(_ title: LocalizedStringKey, subtitle: String? = nil) -> some View {
        modifier(LargeTitleScreen(title: title, subtitle: subtitle))
    }
}

/// Reads the environment locale so the modifier re-applies on an in-app
/// language switch: `navigationTitle` hands a resolved string to the UIKit
/// bar, and a screen that is on screen during the switch (Settings, where
/// the picker lives) kept its title in the previous language while every
/// `Text` below it had already changed (fix 2026-10-09).
private struct LargeTitleScreen: ViewModifier {
    let title: LocalizedStringKey
    let subtitle: String?
    @Environment(\.locale) private var locale

    func body(content: Content) -> some View {
        // The read re-runs this body on a language switch; the explicit
        // bundle changes the Text value with it — `Text(title)` alone was
        // compared equal and the bar kept the previously resolved string.
        let _ = locale
        return content
            .navigationTitle(Text(title, bundle: AppLanguage.current))
            .navigationBarTitleDisplayMode(.large)
            .modifier(NavigationSubtitleModifier(subtitle: subtitle))
    }
}

private struct NavigationSubtitleModifier: ViewModifier {
    let subtitle: String?

    func body(content: Content) -> some View {
        if let subtitle, #available(iOS 26.0, *) {
            content.navigationSubtitle(subtitle)
        } else {
            content
        }
    }
}
