import SwiftUI

/// Global guard against absurd numeric input (user decision 2026-07-14):
/// every free-typed numeric field caps its digit count, so values like
/// "323234234234234" simply can't be entered. Works on typing and paste.
private struct NumericInputLimit: ViewModifier {
    @Binding var text: String
    let maxDigits: Int

    func body(content: Content) -> some View {
        content.onChange(of: text) { _, newValue in
            if newValue.count > maxDigits {
                text = String(newValue.prefix(maxDigits))
            }
        }
    }
}

extension View {
    /// Caps a numeric text field at `maxDigits` characters (default 4 → 9999).
    func numericInputLimit(_ text: Binding<String>, maxDigits: Int = 4) -> some View {
        modifier(NumericInputLimit(text: text, maxDigits: maxDigits))
    }
}
