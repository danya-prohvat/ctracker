import SwiftUI

/// Touch-down feedback that doesn't wait for the button to register: a
/// zero-distance drag (simultaneous, so the tap and scrolling keep working)
/// flips `pressed` the moment the finger lands, and the view squeezes, dims
/// and ticks a soft haptic right away; a finger that moves on to scroll
/// releases the effect. For the Today empty-state CTAs (user request
/// 2026-11-11): `ButtonStyle.isPressed` inside a ScrollView arrives too late
/// for a quick tap, so those buttons looked inert. Pair with `.plain`.
struct InstantPressEffect: ViewModifier {
    var scale: CGFloat = 0.95
    @State private var pressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? scale : 1)
            .opacity(pressed ? 0.85 : 1)
            .animation(pressed ? .easeOut(duration: 0.08)
                               : .spring(response: 0.32, dampingFraction: 0.55),
                       value: pressed)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: pressed) { _, isDown in isDown }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Release well before the scroll view's own ~10 pt
                        // pan threshold: once the scroll takes the touch the
                        // drag may be cancelled without `onEnded`, and the
                        // button would stay squeezed.
                        let moved = hypot(value.translation.width, value.translation.height)
                        pressed = moved < 6
                    }
                    .onEnded { _ in pressed = false }
            )
    }
}

extension View {
    /// Instant squeeze + dim + soft haptic on touch-down (see `InstantPressEffect`).
    func instantPressEffect(scale: CGFloat = 0.95) -> some View {
        modifier(InstantPressEffect(scale: scale))
    }
}
