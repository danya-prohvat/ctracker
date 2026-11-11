import SwiftUI

/// The two CTAs of the Today empty state (user decision 2026-11-11): a filled
/// "Scan a barcode" and a soft-green "Add food". Same sizes and styles as the
/// product-form actions so the pair reads as one family across the app; the
/// press feedback is `instantPressEffect` (touch-down, not `isPressed`),
/// because inside the Today scroll a quick tap never showed the squeeze.
/// Scanning is put first because the scanner is the fastest way to log a
/// packaged product and used to be hidden two levels deep; "Add food" opens
/// the new-product form directly (the list is empty for a newcomer).
struct DayEmptyStateActions: View {
    let onScan: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onScan) {
                label("Scan a barcode", systemImage: "barcode.viewfinder")
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                            .fill(Theme.accentStrong)
                    )
            }
            .buttonStyle(.plain)
            .instantPressEffect()

            Button(action: onAdd) {
                label("Add food", systemImage: "plus")
                    .foregroundStyle(Theme.accentDeep)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                            .fill(Theme.accentSoft)
                    )
            }
            .buttonStyle(.plain)
            .instantPressEffect()
        }
    }

    private func label(_ title: LocalizedStringKey, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
            Text(title)
                .font(.body.weight(.semibold))
                .ctaFit()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
    }
}

#Preview {
    ZStack {
        AppBackground()
        DayEmptyStateActions(onScan: {}, onAdd: {})
            .padding(20)
    }
}
