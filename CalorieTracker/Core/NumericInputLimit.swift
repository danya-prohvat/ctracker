import SwiftUI

/// Shared sanitizer for free-typed numeric input: digits with at most one
/// decimal separator and one fraction digit (user decision 2026-07-16), the
/// integer part capped at `maxDigits` so values like "323234234234234" simply
/// can't be entered. Works on typing and paste.
enum NumericInput {
    /// Accepted decimal separators. `Character.isNumber` admits Arabic-Indic
    /// digits, so the Arabic separator "٫" (U+066B) — what ar keyboards and
    /// formatters produce — must survive too, or a prefilled "١٥٠٫٥" (150.5)
    /// silently collapses into 1505.
    private static let separators: Set<Character> = [".", ",", "٫"]

    static func limited(_ raw: String, maxDigits: Int) -> String {
        var integer = ""
        var fraction = ""
        var separator: Character?
        for ch in raw {
            if ch.isNumber {
                if separator == nil {
                    if integer.count < maxDigits { integer.append(ch) }
                } else if fraction.isEmpty {
                    fraction.append(ch)
                }
            } else if separator == nil, separators.contains(ch) {
                separator = ch
            }
        }
        guard let separator else { return integer }
        return "\(integer.isEmpty ? "0" : integer)\(separator)\(fraction)"
    }
}

private struct NumericInputLimit: ViewModifier {
    @Binding var text: String
    let maxDigits: Int

    func body(content: Content) -> some View {
        content.onChange(of: text) { _, newValue in
            let limited = NumericInput.limited(newValue, maxDigits: maxDigits)
            if limited != newValue { text = limited }
        }
    }
}

extension View {
    /// Caps a numeric text field at `maxDigits` integer digits (default 4 →
    /// 9999) plus at most one decimal place.
    func numericInputLimit(_ text: Binding<String>, maxDigits: Int = 4) -> some View {
        modifier(NumericInputLimit(text: text, maxDigits: maxDigits))
    }
}
