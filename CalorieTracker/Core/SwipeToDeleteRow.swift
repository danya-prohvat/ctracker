import SwiftUI

/// A row that reveals a trailing 88 pt Delete button on a leading swipe
/// (RTL-aware), matching the diary list. Tapping an open row closes it; tapping
/// a closed row forwards `onTap`. The content sits on an opaque `Theme.card` so
/// it slides cleanly over the delete button. Host inside a card that clips to
/// its corner radius so the button follows the rounded edges.
struct SwipeToDeleteRow<Content: View>: View {
    var onTap: () -> Void
    var onDelete: () -> Void
    var deleteAccessibilityLabel: LocalizedStringKey = "Delete"
    @ViewBuilder var content: Content

    @Environment(\.layoutDirection) private var layoutDirection
    @State private var offset: CGFloat = 0
    @State private var isOpen = false

    private let revealWidth: CGFloat = 88
    /// Sign of the slide that exposes the trailing delete button (RTL-aware).
    private var slide: CGFloat { layoutDirection == .rightToLeft ? 1 : -1 }

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteButton
                .opacity(offset == 0 ? 0 : 1)
            content
                .background(Theme.card)
                .offset(x: offset)
                .onTapGesture {
                    if isOpen { setOpen(false) } else { onTap() }
                }
                .gesture(dragGesture)
        }
        .clipped()
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Text("Delete")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: revealWidth)
                .frame(maxHeight: .infinity)
                .background(Theme.destructive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(deleteAccessibilityLabel)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                let base = isOpen ? slide * revealWidth : 0
                let proposed = base + value.translation.width
                if slide < 0 {
                    offset = min(0, max(slide * revealWidth, proposed))
                } else {
                    offset = max(0, min(revealWidth, proposed))
                }
            }
            .onEnded { _ in
                setOpen(abs(offset) > revealWidth / 2)
            }
    }

    private func setOpen(_ open: Bool) {
        withAnimation(.spring(duration: 0.25)) {
            isOpen = open
            offset = open ? slide * revealWidth : 0
        }
    }
}
