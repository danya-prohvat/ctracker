import SwiftUI
import SwiftData

/// The "Logged" card: diary rows separated by hairlines inside one glass card,
/// with an optional "Add food to this day" footer for calendar day details.
struct DiaryListCard: View {
    let entries: [DiaryEntry]
    let unitSystem: UnitSystem
    let showsAddFooter: Bool
    let onTap: (DiaryEntry) -> Void
    let onDelete: (DiaryEntry) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.persistentModelID) { index, entry in
                DiaryRow(
                    entry: entry,
                    unitSystem: unitSystem,
                    onTap: { onTap(entry) },
                    onDelete: { onDelete(entry) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
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
        .buttonStyle(.pressableCard)
    }
}

/// Shared "+ Add food to this day" label: SF plus glyph + accent text,
/// the Health-style "Add Data" affordance. Used by the logged card footer
/// and the empty-day card.
struct AddFoodInlineLabel: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(Theme.accentIcon)
            Text("Add food to this day")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accentIcon)
        }
    }
}
