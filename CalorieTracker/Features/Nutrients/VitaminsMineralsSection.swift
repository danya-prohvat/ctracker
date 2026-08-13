import SwiftUI
import SwiftData

/// Expandable "Nutrients" block at the bottom of the day summary
/// card (spec §2.5/§4). Collapsed it shows how many nutrients are tracked;
/// expanded it lists each enabled nutrient with the consumed total and, when
/// a goal exists, a thin progress bar (prototype style). Embed inside the
/// summary card's VStack — it draws its own hairline top border.
struct VitaminsMineralsSection: View {
    let entries: [DiaryEntry]
    let settings: UserSettings
    /// The day being shown — the list reflects the nutrients tracked on *that*
    /// day, not the current global set, so history stays truthful (spec §2.1).
    let dayKey: String

    @State private var isExpanded = false

    private var defs: [NutrientDef] { settings.enabledNutrientDefs(on: dayKey) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)

            headerRow
                .padding(.top, 16)

            if isExpanded {
                VStack(spacing: 16) {
                    ForEach(defs) { def in
                        NutrientProgressRow(
                            def: def,
                            consumed: consumed(def.id),
                            goal: settings.goal(for: def.id)
                        )
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    private var headerRow: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nutrients")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(defs.count) tracked")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    if isExpanded {
                        Text("Hide")
                    } else {
                        Text("Show")
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Nutrients")
        .accessibilityHint(isExpanded ? "Collapses the list" : "Expands the list")
    }

    /// Total consumed for a nutrient across the day's entries (frozen snapshots).
    /// Nil = "no data": entries exist but none carries this nutrient, so the row
    /// shows "—" instead of a misleading 0. An empty day is a real 0 — nothing
    /// eaten means nothing consumed.
    private func consumed(_ id: String) -> Double? {
        if entries.isEmpty { return 0 }
        let values = entries.compactMap { $0.microValue(id) }
        return values.isEmpty ? nil : values.reduce(0, +)
    }
}

#Preview {
    VitaminsMineralsPreviewHost()
        .modelContainer(PreviewData.container)
}

private struct VitaminsMineralsPreviewHost: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [DiaryEntry]

    var body: some View {
        let settings = UserSettings.current(in: context)
        settings.enabledNutrients = ["fiber", "sugar", "calcium", "iron", "vitaminD", "transFat"]

        return ZStack {
            AppBackground()
            VitaminsMineralsSection(entries: entries, settings: settings, dayKey: DayKey.today)
                .padding(22)
                .glassCard()
                .padding(20)
        }
    }
}
