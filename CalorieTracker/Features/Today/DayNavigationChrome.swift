import SwiftUI

/// Applies the tab-root large title or the pushed-detail nav bar depending on
/// how `DayView` is shown. Date labels are verbatim `Text` (never localized as
/// keys); "Today" is the localized root title. The root also carries the
/// scanner shortcut in the trailing bar slot (user decision 2026-11-11), so
/// scanning stays one tap away once the empty-state CTAs are gone.
struct DayNavigationChrome: ViewModifier {
    let isPresented: Bool
    let dayLabel: String
    let subtitle: String
    let onBack: () -> Void
    var onScan: (() -> Void)? = nil

    func body(content: Content) -> some View {
        if isPresented {
            content.detailNavBar(
                title: Text(dayLabel),
                onBack: onBack
            )
        } else {
            content
                .largeTitleScreen("Today", subtitle: subtitle)
                .toolbar {
                    if let onScan {
                        ToolbarItem(placement: .topBarTrailing) {
                            ScanBarcodeBarButton(action: onScan)
                        }
                    }
                }
        }
    }
}

/// Nav-bar scanner shortcut: an SF Symbol in the accent label color, same as
/// the Back control (iOS 26 wraps toolbar items in glass on its own).
struct ScanBarcodeBarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "barcode.viewfinder")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.accentLabel)
        }
        .accessibilityLabel("Scan a barcode")
    }
}

/// Identifiable wrapper so `.sheet(item:)` can present a quantity editor for a
/// tapped entry without relying on model Identifiable semantics.
struct EditingEntry: Identifiable {
    let id = UUID()
    let entry: DiaryEntry
}
