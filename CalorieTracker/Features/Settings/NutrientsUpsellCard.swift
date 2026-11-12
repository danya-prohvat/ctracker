import SwiftUI

/// Soft green card above the nutrient groups for free users (user decision
/// 2026-11-12): "Track all 37 nutrients · 4 free, 33 with Premium" → paywall.
/// Counts come from the catalog and `PremiumGate.freeNutrientIDs`, never
/// hardcoded. Hidden for premium users (see `NutrientGoalsSection`).
struct NutrientsUpsellCard: View {
    let action: () -> Void

    private var total: Int { NutrientCatalog.all.count }
    private var free: Int { PremiumGate.freeNutrientIDs.count }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SettingsRowIcon(systemName: "sparkles", tint: Theme.tileGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Track all \(total) nutrients")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.accentDeep)
                    Text("\(free) free · \(total - free) with Premium")
                        .font(.caption)
                        .foregroundStyle(Theme.accentLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: 12)
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accentLabel)
            }
            .settingsIconRowPadding()
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressableCard)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        AppBackground()
        NutrientsUpsellCard {}
            .padding(20)
    }
}

#Preview("Dark") {
    ZStack {
        AppBackground()
        NutrientsUpsellCard {}
            .padding(20)
    }
    .preferredColorScheme(.dark)
}
