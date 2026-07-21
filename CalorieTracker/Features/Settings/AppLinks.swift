import SwiftUI
import SafariServices

/// External links used by Settings, onboarding and the paywall.
///
/// TODO: `privacyURL` / `termsURL` are placeholders — replace with the real
/// hosted policy pages before release.
enum AppLinks {
    static let privacyURL = fixedURL("https://example.com/ctracker/privacy")
    static let termsURL = fixedURL("https://example.com/ctracker/terms")
    /// "Calorie Counter & Food Log" — Apple ID from App Store Connect (2026-07-21).
    static let appStoreURL = fixedURL("https://apps.apple.com/app/id6789442226")
    /// App Store "Write a review" deep link — opens the store page with the
    /// rating panel up. Unlike `requestReview()`, this always works, so it is
    /// the right action for an explicit "Rate the app" button (the in-app
    /// dialog is system-throttled and may silently not appear). Derived from
    /// `appStoreURL` so the app id is replaced in one place before release.
    static let writeReviewURL: URL = {
        var components = URLComponents(url: appStoreURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "action", value: "write-review")]
        return components?.url ?? appStoreURL
    }()
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
