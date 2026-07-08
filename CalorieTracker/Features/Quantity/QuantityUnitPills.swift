import SwiftUI

/// Compact unit switcher of the quantity sheet (g/oz or ml/fl oz depending on
/// the product's basis). Selected pill = accent, others = white with a border.
struct QuantityUnitPills: View {
    let units: [FoodUnit]
    let selectedUnit: FoodUnit
    let onSelect: (FoodUnit) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(units) { unit in
                let selected = unit == selectedUnit
                Button {
                    onSelect(unit)
                } label: {
                    Text(LocalizedStringKey(unit.label))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selected ? .white : Theme.textStrong)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(selected ? Theme.accent : Color.white))
                        .overlay(
                            Capsule().strokeBorder(selected ? .clear : Color(hex: 0xE2E2E6), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        QuantityUnitPills(units: [.g, .oz], selectedUnit: .g, onSelect: { _ in })
    }
}
