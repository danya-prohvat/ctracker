import AudioToolbox
import UIKit

/// Success feedback for a camera-recognized barcode: success haptic plus the
/// short system "tink" (1057). The same-code debounce window lives here too so
/// the interval is defined in one place.
enum ScanFeedback {
    /// Window in which a re-report of the same barcode is ignored (spec §7).
    static let debounceInterval: TimeInterval = 2

    @MainActor
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1057)
    }
}
