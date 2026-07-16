import SwiftUI
import UIKit

/// Blurs whatever text field is focused — hides the keyboard and the cursor.
/// UIKit-level so callers don't need to thread `FocusState` around.
@MainActor
func hideKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
    )
}

extension View {
    /// Hides the keyboard when the user taps something that doesn't consume
    /// the tap itself (empty space, captions). Fields, buttons and toggles
    /// keep working — they swallow their own taps before this fires.
    func dismissesKeyboardOnTap() -> some View {
        onTapGesture { hideKeyboard() }
    }
}
