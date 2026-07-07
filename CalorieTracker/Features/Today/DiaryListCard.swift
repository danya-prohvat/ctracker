import SwiftUI
import SwiftData

/// The "Logged" card: diary rows separated by hairlines inside one glass card,
/// with an optional "Add food to this day" footer for calendar day details.
struct DiaryListCard: View {
    let entries: [DiaryEntry]
    let showsAddFooter: Bool
    let onTap: (DiaryEntry) -> Void
    let onDelete: (DiaryEntry) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.persistentModelID) { index, entry in
                DiaryRow(
                    entry: entry,
                    onTap: { onTap(entry) },
                    onDelete: { onDelete(entry) }
                )
                if showsAddFooter || index < entries.count - 1 {
                    Rectangle()
                        .fill(Theme.separator)
                        .frame(height: 1)
                }
            }
            if showsAddFooter {
                addFooter
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        .glassCard()
    }

    private var addFooter: some View {
        Button(action: onAdd) {
            AddFoodInlineLabel()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 15)
                .padding(.horizontal, 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Shared "+ Add food to this day" label: green icon circle + accent text.
/// Used by the logged card footer and the empty-day card.
struct AddFoodInlineLabel: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Theme.accentSoftAlt)
                    .frame(width: 26, height: 26)
                Text(verbatim: "+")
                    .font(.system(size: 19, weight: .light))
                    .foregroundStyle(Theme.accentIcon)
                    .offset(y: -1)
            }
            Text("Add food to this day")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.accentIcon)
        }
    }
}
