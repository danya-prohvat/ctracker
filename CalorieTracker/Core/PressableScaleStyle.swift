import SwiftUI

/// Scales the label down while pressed — the native "squishy" button feel.
/// The app-wide press feedback for button-shaped controls (FAB, keypad keys,
/// CTAs, action cards). List-style rows and grid cells stay `.plain`.
struct PressableScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            // Press-in is near-instant so a quick tap still shows the squeeze
            // (a 0.2 s ease barely moved before the finger lifted — the Today
            // CTAs looked inert, 2026-11-11); the release springs back.
            .animation(configuration.isPressed ? .easeOut(duration: 0.06) : .snappy(duration: 0.25),
                       value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableScaleStyle {
    /// Standard squeeze for compact controls (round buttons, keypad keys).
    static var pressableScale: PressableScaleStyle { PressableScaleStyle() }
    /// Subtler squeeze for wide surfaces (full-width CTAs, action cards).
    static var pressableCard: PressableScaleStyle { PressableScaleStyle(scale: 0.97) }
}
