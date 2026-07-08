import SwiftUI

/// One diary row inside the logged card: name + "80 g · P10 F5 C48" and the
/// kcal column. Swiping toward the leading edge reveals an 88 pt Delete
/// button (prototype style); tapping the row edits the quantity.
struct DiaryRow: View {
    let entry: DiaryEntry
    var onTap: () -> Void
    var onDelete: () -> Void

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
            rowContent
                .background(Theme.card)
                .offset(x: offset)
                .onTapGesture {
                    if isOpen { setOpen(false) } else { onTap() }
                }
                .gesture(dragGesture)
        }
        .clipped()
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.productName)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
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
        .accessibilityLabel("Delete entry")
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
