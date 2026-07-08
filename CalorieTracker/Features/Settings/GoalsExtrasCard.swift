import SwiftUI

/// Extra goal options kept from the spec (not in the prototype): the
/// "Calculate for me" calculator link and the Net carbs toggle, styled as a
/// glass rows card below the goals cards.
struct GoalsExtrasCard: View {
    @Binding var showCalculator: Bool
    @Binding var netCarbs: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(spacing: 0) {
                calculatorRow
                Rectangle()
                    .fill(Theme.separator)
                    .frame(height: 1)
                netCarbsRow
            }
            .glassCard(cornerRadius: 14)

            Text("Adds a net carbs line (carbs − fiber) to the day summary. Useful for keto and low-carb diets.")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
                .padding(.horizontal, 6)
        }
    }

    private var calculatorRow: some View {
        Button {
            showCalculator = true
        } label: {
            HStack {
                Text("Calculate for me")
                    .font(.callout)
                    .foregroundStyle(Theme.accentLabel)
                Spacer(minLength: 8)
                Image(systemName: "wand.and.stars")
                    .font(.subheadline)
                    .foregroundStyle(Theme.accentLabel)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var netCarbsRow: some View {
        Toggle(isOn: $netCarbs) {
            Text("Net carbs")
                .font(.callout)
                .foregroundStyle(Theme.textPrimary)
        }
        .tint(Theme.accent)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

#Preview {
    ZStack {
        AppBackground()
        GoalsExtrasCard(showCalculator: .constant(false), netCarbs: .constant(true))
            .padding(20)
    }
}
