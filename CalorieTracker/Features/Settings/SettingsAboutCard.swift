import SwiftUI

/// "About" card: rate / share / policy rows with icon tiles and trailing
/// chevrons. Actions are unchanged — only the container is restyled.
struct SettingsAboutCard: View {
    @Environment(\.openURL) private var openURL

    @State private var webLink: SettingsWebLink?

    var body: some View {
        VStack(spacing: 0) {
            // Deep link to the App Store review panel, not `requestReview()` —
            // the in-app dialog is throttled and can silently no-op on an
            // explicit tap.
            row("Rate the app", icon: "star", tint: Theme.tileSand) {
                openURL(AppLinks.writeReviewURL)
            }
            SettingsRowDivider()
            shareRow
            SettingsRowDivider()
            row("Privacy Policy", icon: "lock.shield", tint: Theme.tileGray) {
                webLink = SettingsWebLink(url: AppLinks.privacyURL)
            }
            SettingsRowDivider()
            row("Terms of Use", icon: "doc.text", tint: Theme.tileGray) {
                webLink = SettingsWebLink(url: AppLinks.termsURL)
            }
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
        .adaptiveSheet(item: $webLink) { link in
            SafariWebView(url: link.url)
                .ignoresSafeArea()
                .presentationDragIndicator(.visible)
        }
    }

    private var shareRow: some View {
        ShareLink(item: AppLinks.appStoreURL) {
            SettingsRowLabel(icon: "square.and.arrow.up", tint: Theme.tileBlue, title: "Share the app")
        }
        .buttonStyle(.plain)
    }

    private func row(
        _ title: LocalizedStringKey,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            SettingsRowLabel(icon: icon, tint: tint, title: title)
        }
        .buttonStyle(.plain)
    }
}

/// Identifiable wrapper so `.sheet(item:)` can present the in-app browser.
fileprivate struct SettingsWebLink: Identifiable {
    let id = UUID()
    let url: URL
}
