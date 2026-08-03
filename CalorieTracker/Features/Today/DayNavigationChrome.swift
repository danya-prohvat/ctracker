import SwiftUI

/// Applies the tab-root large title or the pushed-detail nav bar depending on
/// how `DayView` is shown. Date labels are verbatim `Text` (never localized as
/// keys); "Today" is the localized root title.
struct DayNavigationChrome: ViewModifier {
    let isPresented: Bool
    let monthLabel: String
    let dayLabel: String
    let subtitle: String
    let onBack: () -> Void

    func body(content: Content) -> some View {
        if isPresented {
            content.detailNavBar(
                backLabel: Text(monthLabel),
                title: Text(dayLabel),
                onBack: onBack
            )
        } else {
            content.largeTitleScreen("Today", subtitle: subtitle)
        }
    }
}

/// Identifiable wrapper so `.sheet(item:)` can present a quantity editor for a
/// tapped entry without relying on model Identifiable semantics.
struct EditingEntry: Identifiable {
    let id = UUID()
    let entry: DiaryEntry
}
