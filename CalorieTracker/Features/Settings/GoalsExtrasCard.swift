import SwiftUI

/// Extra goal options kept from the spec (not in the prototype): the
/// "Calculate for me" calculator row and the Net carbs switch, as icon-tile
/// rows in one card (user decision 2026-11-12 — the long footnote under the
/// card became the row's one-line subtitle).
struct GoalsExtrasCard: View {
    @Binding var showCalculator: Bool
    @Binding var netCarbs: Bool

    var body: some View {
        VStack(spacing: 0) {
            calculatorRow
            SettingsRowDivider()
            netCarbsRow
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    private var calculatorRow: some View {
        Button {
            showCalculator = true
        } label: {
            SettingsRowLabel(
                icon: "wand.and.stars",
                tint: Theme.tileGreen,
                title: "Calculate for me",
                subtitle: Text("From your age, weight and activity")
            )
        }
        .buttonStyle(.plain)
    }

    // Same shape as every other switch row: explicit label + hidden-label
    // Toggle (the app switch style draws only the switch).
    private var netCarbsRow: some View {
        HStack(spacing: 12) {
            SettingsRowIcon(systemName: "leaf.fill", tint: Theme.tileTeal)
            VStack(alignment: .leading, spacing: 2) {
                Text("Net carbs")
                    .font(.callout)
                    .foregroundStyle(Theme.textPrimary)
                Text("Carbs − fiber, for keto")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 12)
            Toggle(isOn: $netCarbs) { Text("Net carbs") }
                .labelsHidden()
                .tint(Theme.accent)
        }
        .settingsIconRowPadding()
    }
}

#Preview {
    ZStack {
        AppBackground()
        GoalsExtrasCard(showCalculator: .constant(false), netCarbs: .constant(true))
            .padding(20)
    }
}

#Preview("Dark") {
    ZStack {
        AppBackground()
        GoalsExtrasCard(showCalculator: .constant(false), netCarbs: .constant(true))
            .padding(20)
    }
    .preferredColorScheme(.dark)
}
