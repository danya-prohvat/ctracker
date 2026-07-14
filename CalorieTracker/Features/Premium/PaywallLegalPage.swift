import Foundation

/// Legal pages reachable from the paywall footer, opened in an in-app Safari
/// sheet (`SafariWebView`).
enum PaywallLegalPage: String, Identifiable {
    case terms
    case privacy

    var id: String { rawValue }

    var url: URL {
        switch self {
        case .terms: return AppLinks.termsURL
        case .privacy: return AppLinks.privacyURL
        }
    }
}
