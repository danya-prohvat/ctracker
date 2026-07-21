import SwiftUI

/// "About" card: rate / share / policy rows with trailing chevrons.
/// Actions are unchanged — only the container is restyled.
struct SettingsAboutCard: View {
    @Environment(\.openURL) private var openURL

    @State private var webLink: SettingsWebLink?

    var body: some View {
        VStack(spacing: 0) {
            // Deep link to the App Store review panel, not `requestReview()` —
            // the in-app dialog is throttled and can silently no-op on an
            // explicit tap.
            row("Rate the app") { openURL(AppLinks.writeReviewURL) }
            SettingsRowDivider()
            shareRow
            SettingsRowDivider()
            row("Privacy Policy") { webLink = SettingsWebLink(url: AppLinks.privacyURL) }
            SettingsRowDivider()
            row("Terms of Use") { webLink = SettingsWebLink(url: AppLinks.termsURL) }
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
        .sheet(item: $webLink) { link in
            SafariWebView(url: link.url)
                .ignoresSafeArea()
                .presentationDragIndicator(.visible)
        }
    }

    private var shareRow: some View {
        ShareLink(item: AppLinks.appStoreURL) {
            rowLabel("Share the app")
        }
        .buttonStyle(.plain)
    }

    private func row(
        _ title: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            rowLabel(title)
        }
        .buttonStyle(.plain)
    }

    private func rowLabel(_ title: LocalizedStringKey) -> some View {
        HStack {
            Text(title)
                .font(.callout)
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 12)
            SettingsRowChevron()
        }
        .settingsRowPadding()
        .contentShape(Rectangle())
    }
}

/// Identifiable wrapper so `.sheet(item:)` can present the in-app browser.
fileprivate struct SettingsWebLink: Identifiable {
    let id = UUID()
    let url: URL
}
