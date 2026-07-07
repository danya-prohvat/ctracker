import SwiftUI
import SafariServices

/// External links used by Settings, onboarding and the paywall.
///
/// TODO: All three URLs are placeholders — replace before release:
///  - `privacyURL` / `termsURL` → the real hosted policy pages
///  - `appStoreURL` → the real App Store URL once the app id is known
enum AppLinks {
    static let privacyURL = fixedURL("https://example.com/ctracker/privacy")
    static let termsURL = fixedURL("https://example.com/ctracker/terms")
    static let appStoreURL = fixedURL("https://apps.apple.com/app/id0000000000")
    /// System page for managing App Store subscriptions.
    static let manageSubscriptionsURL = fixedURL("https://apps.apple.com/account/subscriptions")

    /// Compile-time constant URLs without force unwrap: a typo trips the
    /// assertion in DEBUG instead of crashing production.
    private static func fixedURL(_ string: String) -> URL {
        guard let url = URL(string: string) else {
            assertionFailure("Invalid static URL: \(string)")
            return URL(fileURLWithPath: "/")
        }
        return url
    }
}

/// In-app browser for policy pages — keeps the user inside the app instead of
/// bouncing them out to Safari.
struct SafariWebView: UIViewControllerRepresentable {
    let url: URL

    init(url: URL) {
        self.url = url
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(Theme.accent)
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
