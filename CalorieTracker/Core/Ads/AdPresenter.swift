import UIKit

/// Resolves the frontmost view controller — full-screen ads (interstitial,
/// rewarded) need a presenter and SwiftUI doesn't hand one out.
@MainActor
enum AdPresenter {
    static var topViewController: UIViewController? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        var top = (windows.first(where: \.isKeyWindow) ?? windows.first)?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
