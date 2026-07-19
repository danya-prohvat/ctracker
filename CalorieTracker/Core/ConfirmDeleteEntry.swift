import SwiftUI

extension View {
    /// Confirmation before deleting a logged diary entry — an "already eaten"
    /// product. Diary history is immutable and a deletion can't be undone, so a
    /// mis-swipe or stray tap must never silently drop an entry; the user always
    /// confirms first (user request 2026-07-19). Bind `entry` to the pending
    /// deletion (set it non-nil to ask); `onConfirm` performs the delete.
    func confirmDeleteEntry(
        _ entry: Binding<DiaryEntry?>,
        onConfirm: @escaping (DiaryEntry) -> Void
    ) -> some View {
        confirmationDialog(
            "Delete this entry?",
            isPresented: Binding(
                get: { entry.wrappedValue != nil },
                set: { if !$0 { entry.wrappedValue = nil } }
            ),
            titleVisibility: .visible,
            presenting: entry.wrappedValue
        ) { item in
            Button("Delete", role: .destructive) {
                // Clear the binding first so the message never re-renders against
                // an already-deleted model, then delete the captured entry.
                entry.wrappedValue = nil
                onConfirm(item)
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("\(item.productName) will be removed from your diary. This can't be undone.")
        }
    }
}
