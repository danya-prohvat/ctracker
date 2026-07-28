import SwiftUI

/// Scales the label down while pressed — the native "squishy" button feel.
/// The app-wide press feedback for button-shaped controls (FAB, keypad keys,
/// CTAs, action cards). List-style rows and grid cells stay `.plain`.
struct PressableScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableScaleStyle {
    /// Standard squeeze for compact controls (round buttons, keypad keys).
    static var pressableScale: PressableScaleStyle { PressableScaleStyle() }
    /// Subtler squeeze for wide surfaces (full-width CTAs, action cards).
    static var pressableCard: PressableScaleStyle { PressableScaleStyle(scale: 0.97) }
}
