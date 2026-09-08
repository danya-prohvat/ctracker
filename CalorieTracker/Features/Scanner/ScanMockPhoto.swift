#if DEBUG
import UIKit

/// Debug-only mock camera for App Store screenshots: launch with
/// `-scanMockPhoto <absolute path>` and the scan viewfinder shows that photo
/// instead of the live camera; the simulator's manual-lookup bar hides so the
/// frame looks like a real scan in progress.
enum ScanMockPhoto {
    static let image: UIImage? = {
        guard let path = UserDefaults.standard.string(forKey: "scanMockPhoto"),
              !path.isEmpty else { return nil }
        return UIImage(contentsOfFile: path)
    }()

    static var isActive: Bool { image != nil }
}
#endif
