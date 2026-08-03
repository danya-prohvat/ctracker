import SwiftUI

/// Quick-amount chips on the quantity screen (spec §5): one tap types a
/// common amount into the keypad field. Values follow the input unit so a tap
/// always yields a round number — 50/100/150/200 for g/ml, whole ounces for
/// the US units. Both label parts (locale-aware number, localized unit
/// symbol) are pre-localized, hence `Text(verbatim:)`.
struct QuantityQuickChips: View {
    let unit: FoodUnit
    /// Receives the keypad-ready string for the tapped amount.
    let onPick: (String) -> Void

    @State private var tapCount = 0

    private var amounts: [Int] {
        switch unit {
        case .g, .ml: return [50, 100, 150, 200]
        case .oz, .floz: return [1, 2, 4, 8]
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(amounts, id: \.self) { amount in
                chip(amount)
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: tapCount)
    }

    // The card background lives inside the label so the whole chip squeezes.
    private func chip(_ amount: Int) -> some View {
        Button {
            tapCount += 1
            onPick(Format.editable(Double(amount)))
        } label: {
            Text(verbatim: "\(Format.amount(Double(amount))) \(unit.label)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .contentShape(RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous))
                .glassCard(cornerRadius: Theme.radiusButton)
        }
        .buttonStyle(.pressableScale)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 12) {
            QuantityQuickChips(unit: .g, onPick: { _ in })
            QuantityQuickChips(unit: .oz, onPick: { _ in })
        }
        .padding(20)
    }
}
