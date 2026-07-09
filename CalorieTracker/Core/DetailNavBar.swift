import SwiftUI

extension View {
    /// Pushed-detail chrome with the native scroll-edge blur: an inline, pinned
    /// title and a green back button (chevron + label). Unlike a hand-drawn
    /// header over the scroll view, the *system* nav bar stays transparent at
    /// the top and blurs its content as the page scrolls under it — the same
    /// behavior as the large-title tab roots (`largeTitleScreen`).
    ///
    /// Pass `Text` (not raw strings) so each caller controls localization: a
    /// literal like `Text("Add food")` localizes; a formatted date like
    /// `Text(dayLabel)` stays verbatim. The back label mirrors the parent
    /// screen (e.g. "9 July" for a page pushed from that day).
    func detailNavBar(
        backLabel: Text,
        title: Text,
        onBack: @escaping () -> Void
    ) -> some View {
        modifier(DetailNavBar(backLabel: backLabel, title: title, onBack: onBack))
    }
}

private struct DetailNavBar: ViewModifier {
    let backLabel: Text
    let title: Text
    let onBack: () -> Void

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.backward")
                                .font(.body.weight(.semibold))
                            backLabel
                        }
                    }
                    .accessibilityLabel("Back")
                }
            }
            .tint(Theme.accentLabel)
    }
}
