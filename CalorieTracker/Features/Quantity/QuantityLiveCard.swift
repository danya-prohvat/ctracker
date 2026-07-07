import SwiftUI

/// Frosted live card of the quantity sheet: the typed quantity + unit and the
/// running totals (kcal / protein / fat / carbs) that update with every key.
struct QuantityLiveCard: View {
    let quantityText: String
    let unitLabel: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double

    var body: some View {
        VStack(spacing: 0) {
            Text("Quantity")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: quantityText)
                    .font(.system(size: 52, weight: .bold))
                    .tracking(-1.5)
                    .foregroundStyle(Theme.textPrimary)
                Text(LocalizedStringKey(unitLabel))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.top, 6)
            .padding(.bottom, 4)

            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
                .padding(.top, 18)

            HStack(spacing: 0) {
                totalColumn(value: Format.kcal(calories), caption: "KCAL", color: Theme.accentLabel)
                totalColumn(value: Format.amount(protein), caption: "PROT", color: Theme.textPrimary)
                totalColumn(value: Format.amount(fat), caption: "FAT", color: Theme.textPrimary)
                totalColumn(value: Format.amount(carbs), caption: "CARB", color: Theme.textPrimary)
            }
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassCard(cornerRadius: 20)
    }

    private func totalColumn(value: String, caption: LocalizedStringKey, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
            Text(caption)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        AppBackground()
        QuantityLiveCard(
            quantityText: "150",
            unitLabel: "g",
            calories: 248, protein: 46.5, fat: 5.4, carbs: 0
        )
        .padding(20)
    }
}
