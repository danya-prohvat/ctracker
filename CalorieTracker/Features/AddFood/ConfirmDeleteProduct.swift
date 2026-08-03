import SwiftUI

/// Confirmation alert for deleting a product from "My products". Deleting only
/// removes it from the database; past diary entries keep their own snapshot
/// (spec §2.1), so history is untouched — the message says exactly that.
/// Mirrors `ConfirmDeleteEntry` in Core.
struct ConfirmDeleteProduct: ViewModifier {
    @Binding var product: Product?
    let onConfirm: (Product) -> Void

    func body(content: Content) -> some View {
        content.alert(
            "Delete product?",
            isPresented: Binding(
                get: { product != nil },
                set: { if !$0 { product = nil } }
            ),
            presenting: product
        ) { product in
            Button("Delete", role: .destructive) { onConfirm(product) }
            Button("Cancel", role: .cancel) {}
        } message: { product in
            Text("“\(product.name)” will be removed from your products. Your logged entries stay.")
        }
    }
}

extension View {
    func confirmDeleteProduct(
        _ product: Binding<Product?>,
        onConfirm: @escaping (Product) -> Void
    ) -> some View {
        modifier(ConfirmDeleteProduct(product: product, onConfirm: onConfirm))
    }
}
