import SwiftUI

/// Readable-width column for full-bleed screens on iPad: caps the content
/// width and centers the capped block. Every cap used in the app is at or
/// above the widest iPhone layout (440 pt), so this is a strict no-op on
/// iPhone.
extension View {
    /// The default 640 includes the screen's own horizontal gutters — apply
    /// AFTER `.padding(.horizontal, …)`. Narrow caps for control blocks
    /// (quantity keypad, scan buttons) are applied directly to the block,
    /// INSIDE the gutters, so the cap constrains the controls themselves and
    /// never shrinks them on iPhone.
    func contentColumn(_ max: CGFloat = 640) -> some View {
        self
            .frame(maxWidth: max)
            .frame(maxWidth: .infinity)
    }
}
