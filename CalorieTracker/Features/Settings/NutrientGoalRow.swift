import SwiftUI
import SwiftData

/// One nutrient row (user decision 2026-11-12): soft group-tinted circle
/// with the nutrient's own glyph (`NutrientGlyphCircle`, lock badge while the
/// nutrient is premium-locked), name, and a toggle that enables tracking. Switched OFF the row is one compact line ("1 300 mg ·
/// daily goal"); switched ON it gets a tinted background, the mini −/+
/// stepper for the daily norm, a "Limit" badge for stay-under nutrients and
/// the catalog hint. Overrides live in `UserSettings.nutrientGoalOverrides`;
/// a value matching the catalog default removes the override.
struct NutrientGoalRow: View {
    @Environment(\.modelContext) private var context

    let def: NutrientDef
    let settings: UserSettings
    let locked: Bool
    let onLockedEnableAttempt: () -> Void

    private var isOn: Bool { settings.enabledNutrients.contains(def.id) }
    private var effectiveGoal: Double? { settings.goal(for: def.id) }

    var body: some View {
        HStack(spacing: 12) {
            tile
            VStack(alignment: .leading, spacing: 4) {
                Text(def.nameKey)
                    .font(.callout)
                    .foregroundStyle(Theme.textPrimary)
                if isOn {
                    stepperLine
                    if let hint = def.hint {
                        Text(hint)
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                } else {
                    normCaption
                }
            }
            Spacer(minLength: 8)
            Toggle(isOn: toggleBinding) {
                Text(def.nameKey)
            }
            .labelsHidden()
            .tint(Theme.accent)
        }
        .settingsIconRowPadding()
        .background(isOn ? Theme.rowActiveFill : .clear)
    }

    private var tile: some View {
        NutrientGlyphCircle(def: def, locked: locked)
    }

    /// Compact off-state line: norm + target semantics ("reach it" vs "stay
    /// under it" — fixed per nutrient in the catalog, not user-editable).
    private var normCaption: some View {
        Group {
            if let goal = effectiveGoal {
                let norm = Format.nutrient(goal, unit: def.unit)
                if def.kind == .limit {
                    Text("\(norm) · daily limit")
                } else {
                    Text("\(norm) · daily goal")
                }
            } else if def.kind == .limit {
                Text("daily limit")
            } else {
                Text("daily goal")
            }
        }
        .font(.caption)
        .foregroundStyle(Theme.textTertiary)
    }

    private var stepperLine: some View {
        HStack(spacing: 8) {
            GoalsStepperCircle(.decrement, size: 24, glyphSize: 16) {
                adjustGoal(by: -step)
            }
            normLabel
                .font(.stat(.footnote, .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(minWidth: 58)
            GoalsStepperCircle(.increment, size: 24, glyphSize: 16) {
                adjustGoal(by: step)
            }
            if def.kind == .limit {
                limitBadge
            }
        }
    }

    private var normLabel: Text {
        if let goal = effectiveGoal {
            return Text(verbatim: Format.nutrient(goal, unit: def.unit))
        }
        return Text(verbatim: "—")
    }

    private var limitBadge: some View {
        Text("Limit")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.warning)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.warningSoft, in: Capsule())
            .badgeFit()
    }

    // MARK: - Goal stepping

    /// Sensible per-nutrient step derived from the magnitude of its norm
    /// (the catalog defines no explicit steps).
    private var step: Double {
        let base = def.defaultDV ?? effectiveGoal ?? 1
        switch base {
        case ..<2: return 0.1
        case ..<10: return 0.5
        case ..<50: return 1
        case ..<200: return 5
        case ..<1000: return 25
        default: return 100
        }
    }

    /// Only positive values that differ from the catalog default are stored;
    /// anything else falls back to the default norm.
    private func adjustGoal(by delta: Double) {
        let raw = max(0, (effectiveGoal ?? 0) + delta)
        let value = (raw * 100).rounded() / 100
        if value > 0, value != def.defaultDV {
            settings.nutrientGoalOverrides[def.id] = value
        } else {
            settings.nutrientGoalOverrides.removeValue(forKey: def.id)
        }
        try? context.save()
    }

    // MARK: - Tracking toggle (premium-gated, unchanged behavior)

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { isOn },
            set: { newValue in
                if newValue && locked {
                    onLockedEnableAttempt()
                    return
                }
                // Freeze the pre-change set as the historical baseline before
                // mutating, so past days keep what they tracked (spec §2.1).
                settings.ensureNutrientTrackingBaseline()
                if newValue {
                    var enabled = Set(settings.enabledNutrients)
                    enabled.insert(def.id)
                    // Preserve catalog order when storing.
                    settings.enabledNutrients = NutrientCatalog.all.map(\.id)
                        .filter { enabled.contains($0) }
                } else {
                    settings.enabledNutrients.removeAll { $0 == def.id }
                }
                // Record the resulting set for today; only today and future days
                // reflect the change.
                settings.recordNutrientTrackingChange()
                try? context.save()
            }
        )
    }
}
