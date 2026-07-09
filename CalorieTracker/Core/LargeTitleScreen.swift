import SwiftUI

extension View {
    /// Native collapsing large title for a tab-root screen: the big title pins
    /// to an inline nav bar on scroll (Health/Fitness behavior). Replaces the
    /// old hand-drawn headers. `subtitle` uses the iOS 26 `navigationSubtitle`
    /// when available and is a no-op below (keeps the iOS 17 target building).
    func largeTitleScreen(_ title: LocalizedStringKey, subtitle: String? = nil) -> some View {
        self
            .navigationTitle(title)
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
