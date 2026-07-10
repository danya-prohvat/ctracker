import UIKit

/// Tactile feedback for key taps, selection changes and successful commits.
/// A thin wrapper over UIKit's feedback generators (pointwise UIKit use); call
/// from the main actor in response to user actions.
@MainActor
enum Haptics {
    /// Light tick for a keypad digit or backspace, like the system keyboard.
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Subtle change for a segmented / unit selection.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Confirmation for a completed log or save.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
