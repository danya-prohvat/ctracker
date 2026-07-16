import SwiftUI

/// "RECENT" caption + horizontally scrolling glass chips of recently logged
/// products (2-tap logging entry point).
struct AddFoodRecentsRow: View {
    let products: [Product]
    let unitSystem: UnitSystem
    let onSelect: (Product) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AddFoodCaption(title: "Recent")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(products) { product in
                        Button {
                            onSelect(product)
                        } label: {
                            AddFoodRecentChip(product: product, unitSystem: unitSystem)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }
}

/// One recent chip: name (14pt semibold) + "380 kcal / 100 g" (12pt secondary).
private struct AddFoodRecentChip: View {
    let product: Product
    let unitSystem: UnitSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(product.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                if product.wasScanned { ScannedBadge() }
            }
            Text("\(Format.kcal(product.calories)) kcal / \(product.basis.per100Compact(unitSystem))")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(minWidth: 116, maxWidth: 158, alignment: .leading)
        .glassCard(cornerRadius: 14)
    }
}

#Preview {
    ZStack {
        AppBackground()
        AddFoodRecentsRow(products: [], unitSystem: .metric, onSelect: { _ in })
            .padding(20)
    }
    .modelContainer(PreviewData.container)
}
