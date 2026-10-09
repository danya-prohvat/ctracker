import SwiftUI

/// A row that reveals trailing action buttons on a leading swipe (RTL-aware),
/// matching the diary list: an 88 pt Delete button, plus an optional Edit
/// button next to it (Mail-style — the destructive action sits at the outer
/// edge). Tapping an open row closes it; tapping a closed row forwards `onTap`.
/// The content sits on an opaque `Theme.card` so it slides cleanly over the
/// buttons. Host inside a card that clips to its corner radius so the buttons
/// follow the rounded edges.
///
/// The drag is a `simultaneousGesture` with an axis lock (fix 2026-09-27):
/// as a plain `.gesture` it competed with the ScrollView, so a finger that
/// landed on a row scrolled with a noticeable hitch. Now the scroll view is
/// never blocked; the row only moves once the first movement is horizontal.
struct SwipeToDeleteRow<Content: View>: View {
    var onTap: () -> Void
    var onDelete: () -> Void
    /// Optional second swipe action, revealed next to Delete.
    var onEdit: (() -> Void)? = nil
    var deleteAccessibilityLabel: LocalizedStringKey = "Delete"
    var editAccessibilityLabel: LocalizedStringKey = "Edit"
    @ViewBuilder var content: Content

    @Environment(\.layoutDirection) private var layoutDirection
    @State private var offset: CGFloat = 0
    @State private var isOpen = false
    /// Locked on the first movement of a drag; vertical = leave it to scroll.
    @State private var dragAxis: Axis?

    private let buttonWidth: CGFloat = 88
    private var revealWidth: CGFloat { onEdit == nil ? buttonWidth : buttonWidth * 2 }
    /// Sign of the on-screen slide that exposes the trailing buttons: toward
    /// the left in LTR, toward the right in RTL. `offset` is kept in SCREEN
    /// space, like the drag translation that feeds it.
    private var slide: CGFloat { layoutDirection == .rightToLeft ? 1 : -1 }
    /// `.offset(x:)` is mirrored by SwiftUI in RTL while `DragGesture`'s
    /// translation is not, so the screen-space value is flipped back before
    /// it is applied (fix 2026-10-09: in Arabic the row slid away from the
    /// finger, out of the clipped card, and the buttons never showed).
    private var appliedOffset: CGFloat { layoutDirection == .rightToLeft ? -offset : offset }

    var body: some View {
        ZStack(alignment: .trailing) {
            actions
                .opacity(offset == 0 ? 0 : 1)
            content
                .background(Theme.card)
                .offset(x: appliedOffset)
                .onTapGesture {
                    if isOpen { setOpen(false) } else { onTap() }
                }
                .simultaneousGesture(dragGesture)
        }
        .clipped()
    }

    private var actions: some View {
        HStack(spacing: 0) {
            if let onEdit {
                actionButton(Text("Edit"), background: Theme.neutralAction,
                             accessibilityLabel: editAccessibilityLabel) {
                    setOpen(false)
                    onEdit()
                }
            }
            actionButton(Text("Delete"), background: Theme.destructive,
                         accessibilityLabel: deleteAccessibilityLabel,
                         action: onDelete)
        }
    }

    private func actionButton(
        _ title: Text, background: Color,
        accessibilityLabel: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            title
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: buttonWidth)
                .frame(maxHeight: .infinity)
                .background(background)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if dragAxis == nil {
                    let t = value.translation
                    dragAxis = abs(t.width) > abs(t.height) ? .horizontal : .vertical
                }
                guard dragAxis == .horizontal else { return }
                let base = isOpen ? slide * revealWidth : 0
                let proposed = base + value.translation.width
                if slide < 0 {
                    offset = min(0, max(slide * revealWidth, proposed))
                } else {
                    offset = max(0, min(revealWidth, proposed))
                }
            }
            .onEnded { _ in
                if dragAxis == .horizontal {
                    setOpen(abs(offset) > revealWidth / 2)
                }
                dragAxis = nil
            }
    }

    private func setOpen(_ open: Bool) {
        withAnimation(.spring(duration: 0.25)) {
            isOpen = open
            offset = open ? slide * revealWidth : 0
        }
    }
}
