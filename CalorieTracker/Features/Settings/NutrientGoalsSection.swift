import SwiftUI
import SwiftData

/// Fiber & sugar stay free; every other nutrient is premium (spec §4, §9).
private let freeNutrientIDs: Set<String> = ["fiber", "sugar"]

/// "Vitamins & minerals" block of the Goals & nutrients page: preset chips
/// plus one glass rows card covering the whole nutrient catalog in order.
struct NutrientGoalsSection: View {
    @Environment(\.modelContext) private var context

    let settings: UserSettings

    @State private var showPaywall = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GoalsSectionCaption("Vitamins & minerals")
                .padding(.top, 6)
            presetChips
            nutrientsCard
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var nutrientsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(NutrientCatalog.all.enumerated()), id: \.element.id) { index, def in
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
        !freeNutrientIDs.contains(def.id)
            && !PremiumGate.isUnlocked(.nutrients, settings: settings)
    }

    // MARK: - Presets (spec §4)

    private var presetChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                presetChip("Basic", preset: NutrientCatalog.presetBasic)
                presetChip("Vitamins & minerals", preset: NutrientCatalog.presetVitaminsMinerals)
                presetChip("All", preset: NutrientCatalog.presetAll)
                presetChip("None", preset: NutrientCatalog.presetNone)
            }
        }
        .padding(.bottom, 2)
    }

    private func presetChip(_ title: LocalizedStringKey, preset: Set<String>) -> some View {
        Button {
            applyPreset(preset)
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.accentDeep)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.accentSoft))
        }
        .buttonStyle(.plain)
    }

    /// Apply a preset preserving catalog order. If premium is locked and the
    /// preset contains premium nutrients, show the paywall and change nothing
    /// ("None" always works).
    private func applyPreset(_ preset: Set<String>) {
        let containsPremium = !preset.subtracting(freeNutrientIDs).isEmpty
        if containsPremium && !PremiumGate.isUnlocked(.nutrients, settings: settings) {
            showPaywall = true
            return
        }
        settings.enabledNutrients = NutrientCatalog.all.map(\.id).filter { preset.contains($0) }
        try? context.save()
    }
}
