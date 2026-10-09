import SwiftUI

/// One nutrient row: name, "consumed / target unit" (or value only when no
/// target, or "—" when no entry has data). Never divides by a nil/zero target.
/// Goal-kind targets stay brand-colored and get a checkmark at ≥100%;
/// limit-kind targets turn amber near the cap and red above it, with the
/// "+X over" spelled out in the caption under the name — next to the value
/// it overflowed a 390 pt screen in de/pl/ru and truncated the name
/// (fix 2026-10-09).
///
/// Shared by the day summary (`VitaminsMineralsSection`) and the calendar's
/// per-period averages (`CalendarNutrientHistoryCard`) so both read identically.
/// In the calendar `consumed` is a mean daily intake compared to the daily goal.
struct NutrientProgressRow: View {
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
                    kindCaption
                        .font(.caption2)
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

    /// "Limit" / "Goal", plus the overage for an exceeded limit. It lives on
    /// this short line so the long translations ("+3,7 ponad limit") have
    /// the whole row width instead of fighting the name on one line.
    private var kindCaption: Text {
        let kind = Text(def.kind == .limit ? "Limit" : "Goal")
            .foregroundStyle(Theme.textTertiary)
        guard def.kind == .limit, let consumed, let goal, goal > 0, consumed > goal else {
            return kind
        }
        // Accessibility: the overage is spelled out, never color alone.
        return kind
            + Text(verbatim: " · ").foregroundStyle(Theme.textTertiary)
            + Text("+\(Format.amount(consumed - goal)) over")
                .foregroundStyle(Theme.destructive)
                .fontWeight(.semibold)
    }

    private var trailingText: Text {
        guard let consumed else {
            return Text(verbatim: "—").foregroundStyle(Theme.textSecondary)
        }
        guard let goal, goal > 0 else {
            return Text(verbatim: Format.nutrient(consumed, unit: def.unit))
                .foregroundStyle(Theme.textSecondary)
        }
        return Text(verbatim: "\(Format.amount(consumed)) / \(Format.nutrient(goal, unit: def.unit))")
            .foregroundStyle(Theme.textSecondary)
    }
}
