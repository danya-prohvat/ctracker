import SwiftUI

/// Presents the add-food flow for a day. The Today root keeps the full-screen
/// cover under its FAB; a pushed calendar day detail shows the same flow as a
/// card sheet so it reads as a modal step, not another push (user request
/// 2026-07-16).
///
/// Either way the flow gets its own NavigationStack rather than a push into
/// the parent one: when DayView is itself a pushed calendar detail, a second
/// `navigationDestination` on the same stack jams navigation (the add tap and
/// the back button both freeze).
struct AddFoodPresentation: ViewModifier {
    let asSheet: Bool
    @Binding var isActive: Bool
    let dayKey: String

    func body(content: Content) -> some View {
        if asSheet {
            content.adaptiveSheet(isPresented: $isActive) {
                flow.presentationDragIndicator(.visible)
            }
        } else {
            content.fullScreenCover(isPresented: $isActive) { flow }
        }
    }

    private var flow: some View {
        NavigationStack { AddFoodSheet(dayKey: dayKey) }
    }
}
