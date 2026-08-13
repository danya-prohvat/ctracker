import Combine
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
    /// the tap itself (empty space, captions). The gesture is only armed while
    /// the keyboard is on screen — a container-level tap gesture that is always
    /// active steals taps from menu `Picker`s inside `Form`, so they silently
    /// stop opening.
    func dismissesKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

private struct DismissKeyboardOnTap: ViewModifier {
    @State private var keyboardVisible = false

    func body(content: Content) -> some View {
        content
            .gesture(
                TapGesture().onEnded { hideKeyboard() },
                including: keyboardVisible ? .all : .subviews
            )
            .onReceive(NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillShowNotification
            )) { _ in keyboardVisible = true }
            .onReceive(NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillHideNotification
            )) { _ in keyboardVisible = false }
    }
}
