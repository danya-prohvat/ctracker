import SwiftUI
import UIKit

/// iPhone keeps the regular bottom sheet; iPad shows the same content as a
/// width-capped bottom sheet (user decision 2026-08-18, replaces both the
/// centered formSheet and the first full-screen take): a clear full-screen
/// cover hosting `PadSheetChrome` — dimmed backdrop, 640pt card anchored to
/// the bottom, grabber with swipe-down to dismiss, tap outside to dismiss.
extension View {
    @ViewBuilder
    func adaptiveSheet<C: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> C
    ) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
                PadSheetChrome { content() }
            }
        } else {
            sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
        }
    }

    @ViewBuilder
    func adaptiveSheet<Item: Identifiable, C: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> C
    ) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            fullScreenCover(item: item, onDismiss: onDismiss) { value in
                PadSheetChrome { content(value) }
            }
        } else {
            sheet(item: item, onDismiss: onDismiss, content: content)
        }
    }
}

/// iPad modal chrome: dim + bottom-anchored rounded card. Lives inside a
/// transparent full-screen cover, so the system slide-up/down transition
/// animates the card like a real sheet.
private struct PadSheetChrome<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder var content: Content

    @State private var dimmed = false
    @State private var dragOffset: CGFloat = 0
    @State private var dismissGuard = AdaptiveSheetDismissGuard()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(dimmed ? 0.25 : 0)
                .ignoresSafeArea()
                .onTapGesture { close() }
            card
        }
        .presentationBackground(.clear)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { dimmed = true }
        }
    }

    private var card: some View {
        content
            .environment(\.adaptiveSheetDismissGuard, dismissGuard)
            .frame(maxWidth: 640)
            .frame(maxHeight: .infinity)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26))
            .overlay(alignment: .top) { grabberStrip }
            .padding(.top, 44)
            .offset(y: max(0, dragOffset))
            .ignoresSafeArea(edges: .bottom)
    }

    /// The grabber owns the swipe-down gesture, so scroll views inside the
    /// content keep their own drags (same affordance as a system sheet).
    private var grabberStrip: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.5))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 36, alignment: .top)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { dragOffset = $0.translation.height }
                    .onEnded { value in
                        if value.translation.height > 140 {
                            close()
                        } else {
                            withAnimation(.spring(duration: 0.3)) { dragOffset = 0 }
                        }
                    }
            )
    }

    /// Backdrop tap and grabber flick funnel here. Guarded content (unsaved
    /// edits, see `adaptiveSheetDismissGuard`) vetoes the close: the card
    /// springs back and the content's `onAttempt` shows its discard
    /// confirmation — mirroring `interactiveDismissDisabled` on iPhone.
    private func close() {
        if dismissGuard.isGuarded {
            withAnimation(.spring(duration: 0.3)) { dragOffset = 0 }
            dismissGuard.onAttempt()
        } else {
            withAnimation(.easeIn(duration: 0.15)) { dimmed = false }
            dismiss()
        }
    }
}
