import SwiftUI

/// Small marker shown next to a product/entry that originated from the barcode
/// scanner (vs. one created manually). Kept as one view so the icon and tint
/// stay consistent across the products list, Recent chips and the diary.
struct ScannedBadge: View {
    /// Overridable so the badge can scale up next to large titles.
    var font: Font = .subheadline.weight(.semibold)

    var body: some View {
        Image(systemName: "barcode.viewfinder")
            .font(font)
            .foregroundStyle(Theme.textSecondary)
            .accessibilityLabel("Scanned")
    }
}
