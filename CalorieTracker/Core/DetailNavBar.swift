import SwiftUI

extension View {
    /// Pushed-detail chrome with the native scroll-edge blur: an inline, pinned
    /// title and the app's one green back button (`BackButtonLabel`, always
    /// "Back"). Unlike a hand-drawn header over the scroll view, the *system*
    /// nav bar stays transparent at the top and blurs its content as the page
    /// scrolls under it — the same behavior as the large-title tab roots
    /// (`largeTitleScreen`).
    ///
    /// Pass `Text` (not a raw string) for the title so each caller controls
    /// localization: a literal like `Text("Add food")` localizes; a formatted
    /// date like `Text(dayLabel)` stays verbatim.
    func detailNavBar(
        title: Text,
        onBack: @escaping () -> Void
    ) -> some View {
        modifier(DetailNavBar(title: title, onBack: onBack))
    }
}

private struct DetailNavBar: ViewModifier {
    let title: Text
    let onBack: () -> Void

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) { BackButtonLabel() }
                        .accessibilityLabel("Back")
                }
            }
            .tint(Theme.accentLabel)
    }
}
