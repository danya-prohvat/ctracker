import SwiftUI

/// "MY PRODUCTS" caption + one glass card listing the user's products.
/// Rows keep the existing edit/delete context menu; the trailing "+" saves a
/// product without logging it (spec §5).
struct AddFoodProductList: View {
    let products: [Product]
    let searchQuery: String
    let onSelect: (Product) -> Void
    let onEdit: (Product) -> Void
    let onDelete: (Product) -> Void
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            caption
            card
        }
    }

    private var caption: some View {
        HStack {
            AddFoodCaption(title: "My products")
            Spacer()
            Button(action: onCreate) {
                Image(systemName: "plus")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accentLabel)
            }
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            if products.isEmpty {
                emptyRow
            } else {
                ForEach(products) { product in
                    Button {
                        onSelect(product)
                    } label: {
                        AddFoodProductRow(product: product)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            onEdit(product)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            onDelete(product)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    if product.id != products.last?.id {
                        Rectangle()
                            .fill(Theme.separator)
                            .frame(height: 1)
                    }
                }
            }
        }
        .glassCard(cornerRadius: 14)
    }

    @ViewBuilder private var emptyRow: some View {
        Group {
            if searchQuery.isEmpty {
                Text("No products yet")
            } else {
                Text("No products match “\(searchQuery)”.")
            }
        }
        .font(.subheadline)
        .foregroundStyle(Theme.textSecondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}

/// One row: name 16pt semibold + "P 13 · F 7 · C 60"; trailing "380 kcal" +
/// "per 100 g" (prototype padding 14/16).
private struct AddFoodProductRow: View {
    let product: Product

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                // Prototype rounds macros to whole grams in list rows.
                Text("P \(Format.amount(product.protein.rounded())) · F \(Format.amount(product.fat.rounded())) · C \(Format.amount(product.carbs.rounded()))")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Format.kcal(product.calories)) kcal")
                    .font(.stat(.subheadline))
                    .foregroundStyle(Theme.textPrimary)
                Text(product.basis.per100Label)
                    .font(.caption2)
                    .foregroundStyle(Theme.textQuaternary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

#Preview {
    ZStack {
        AppBackground()
        AddFoodProductList(products: [], searchQuery: "kiwi",
                           onSelect: { _ in }, onEdit: { _ in },
                           onDelete: { _ in }, onCreate: {})
            .padding(20)
    }
    .modelContainer(PreviewData.container)
}
