import SwiftUI

/// Prefill context for the New-product modal: blank, scan-prefilled, or with a
/// scanned barcode to attach.
struct NewProductRoute {
    var prefill: LoggableFood? = nil
    var barcode: String? = nil
}

/// A modal step of the add-food flow. The list is a page (spec §5); quantity and
/// new product are presented as sheets over it.
struct AddSheet: Identifiable {
    enum Kind {
        case quantity(LoggableFood)
        case newProduct(NewProductRoute)
    }
    let id = UUID()
    let kind: Kind
}

/// The New-product modal: the form, then a pushed quantity step on "continue",
/// kept inside the sheet's own stack so "Back" returns to the form and a
/// completed log dismisses the whole modal.
struct NewProductLogSheet: View {
    let route: NewProductRoute
    let dayKey: String
    let unitSystem: UnitSystem
    let onLogged: () -> Void

    @State private var quantityFood: LoggableFood?

    var body: some View {
        NavigationStack {
            NewProductForm(mode: .logging,
                           prefill: route.prefill,
                           prefillBarcode: route.barcode,
                           onContinue: { quantityFood = $0 })
                .navigationDestination(item: $quantityFood) { food in
                    QuantityLogView(food: food, dayKey: dayKey,
                                    unitSystem: unitSystem, onLogged: onLogged)
                }
        }
    }
}
