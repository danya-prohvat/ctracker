import SwiftUI
import SwiftData

/// Nutrient block of the Goals & nutrients page: a captioned rows card per
/// catalog group (macrominerals, trace elements, vitamins, other), keeping
/// the canonical catalog order inside each.
struct NutrientGoalsSection: View {
    let settings: UserSettings

    @State private var showPaywall = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(NutrientGroup.allCases) { group in
                GoalsSectionCaption(group.title)
                    .padding(.top, 6)
                groupCard(group)
            }
        }
        .adaptiveSheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func groupCard(_ group: NutrientGroup) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(NutrientCatalog.inGroup(group).enumerated()), id: \.element.id) { index, def in
                if index > 0 {
                    Rectangle()
                        .fill(Theme.separator)
                        .frame(height: 1)
                }
                NutrientGoalRow(
                    def: def,
                    settings: settings,
                    locked: isLocked(def),
                    onLockedEnableAttempt: { showPaywall = true }
                )
            }
        }
        .glassCard(cornerRadius: 14)
    }

    private func isLocked(_ def: NutrientDef) -> Bool {
        !PremiumGate.isNutrientUnlocked(def.id, settings: settings)
    }
}
