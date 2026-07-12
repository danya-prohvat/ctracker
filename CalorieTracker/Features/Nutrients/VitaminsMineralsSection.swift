import SwiftUI
import SwiftData

/// Expandable "Vitamins & minerals" block at the bottom of the day summary
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
                    Text("Vitamins & minerals")
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
        .accessibilityLabel("Vitamins and minerals")
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

/// One expanded row: name, "consumed / target unit" (or value only when no
/// target, or "—" when no entry has data). Never divides by a nil/zero target.
/// Goal-kind targets stay brand-colored and get a checkmark at ≥100%;
/// limit-kind targets turn amber near the cap and red + "+X over" above it.
private struct NutrientProgressRow: View {
    let def: NutrientDef
    let consumed: Double?
    let goal: Double?

    /// Consumed-to-target ratio; nil without data or a positive target.
    private var ratio: Double? {
        guard let consumed, let goal, goal > 0 else { return nil }
        return consumed / goal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(def.nameKey)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textStrong)
                        .lineLimit(1)
                    Text(def.kind == .limit ? "Limit" : "Goal")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer(minLength: 8)
                HStack(spacing: 5) {
                    if def.kind == .goal, let ratio, ratio >= 1 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(Theme.accent)
                            .accessibilityLabel("Goal reached")
                    }
                    trailingText
                        .font(.stat(.footnote, .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            if let consumed, let goal, goal > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: 0x3C3C43).opacity(0.1))
                        Capsule()
                            .fill(barColor)
                            .frame(width: max(3, geo.size.width * min(consumed / goal, 1)))
                            .animation(.easeOut(duration: 0.35), value: consumed)
                    }
                }
                .frame(height: 6)
            }
        }
    }

    /// Goals never warn — exceeding one is success. Limits go amber from 90%
    /// and red over 100% (exceeding a limit must not read as completion).
    private var barColor: Color {
        guard def.kind == .limit, let ratio else { return Theme.microBar }
        if ratio > 1 { return Theme.destructive }
        if ratio >= 0.9 { return Theme.warning }
        return Theme.microBar
    }

    private var trailingText: Text {
        guard let consumed else {
            return Text(verbatim: "—").foregroundStyle(Theme.textSecondary)
        }
        guard let goal, goal > 0 else {
            return Text(verbatim: Format.nutrient(consumed, unit: def.unit))
                .foregroundStyle(Theme.textSecondary)
        }
        let base = Text(verbatim: "\(Format.amount(consumed)) / \(Format.nutrient(goal, unit: def.unit))")
            .foregroundStyle(Theme.textSecondary)
        guard def.kind == .limit, consumed > goal else { return base }
        // Accessibility: the overage is spelled out, never color alone.
        return base
            + Text(verbatim: " · ").foregroundStyle(Theme.textSecondary)
            + Text("+\(Format.amount(consumed - goal)) over")
                .foregroundStyle(Theme.destructive)
                .fontWeight(.semibold)
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
