import SwiftUI
import SwiftData

/// Nutrient block of the Goals & nutrients page: for free users a soft green
/// upsell card first (user decision 2026-11-12), then a captioned rows card
/// per catalog group (macrominerals, trace elements, vitamins, other) with an
/// "N of M on" counter in the caption, keeping the canonical catalog order
/// inside each group.
struct NutrientGoalsSection: View {
    let settings: UserSettings

    @State private var showPaywall = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !PremiumGate.isPremium(settings: settings) {
                NutrientsUpsellCard { showPaywall = true }
                    .padding(.top, 2)
            }
            ForEach(NutrientGroup.allCases) { group in
                groupHeader(group)
                    .padding(.top, 6)
                groupCard(group)
            }
        }
        .adaptiveSheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func groupHeader(_ group: NutrientGroup) -> some View {
        let defs = NutrientCatalog.inGroup(group)
        let on = defs.filter { settings.enabledNutrients.contains($0.id) }.count
        return HStack(alignment: .firstTextBaseline) {
            GoalsSectionCaption(group.title)
            Spacer(minLength: 8)
            Text("\(on) of \(defs.count) on")
                .font(.footnote)
                .foregroundStyle(Theme.textTertiary)
                .padding(.horizontal, 6)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: on)
        }
    }

    private func groupCard(_ group: NutrientGroup) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(NutrientCatalog.inGroup(group).enumerated()), id: \.element.id) { index, def in
                if index > 0 {
                    SettingsRowDivider()
                }
                NutrientGoalRow(
                    def: def,
                    settings: settings,
                    locked: isLocked(def),
                    onLockedEnableAttempt: { showPaywall = true }
                )
            }
        }
        // Tinted ON rows must not poke out of the card's rounded corners.
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    private func isLocked(_ def: NutrientDef) -> Bool {
        !PremiumGate.isNutrientUnlocked(def.id, settings: settings)
    }
}
