import SwiftUI

/// One diary row inside the logged card: name + "80 g · P10 F5 C48" and the
/// kcal column. Swiping toward the leading edge reveals an 88 pt Delete
/// button (prototype style); tapping the row edits the quantity.
struct DiaryRow: View {
    let entry: DiaryEntry
    var onTap: () -> Void
    var onDelete: () -> Void

    var body: some View {
        SwipeToDeleteRow(
            onTap: onTap,
            onDelete: onDelete,
            deleteAccessibilityLabel: "Delete entry"
        ) {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.productName)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    if entry.wasScanned { ScannedBadge() }
                }
                Text("\(Format.amount(entry.quantity)) \(entry.basis.canonicalUnit.label) · P\(Format.amount(entry.protein.rounded())) F\(Format.amount(entry.fat.rounded())) C\(Format.amount(entry.carbs.rounded()))")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text(Format.kcal(entry.calories))
                    .font(.stat(.body, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("kcal")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.textQuaternary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .contentShape(Rectangle())
    }
}
