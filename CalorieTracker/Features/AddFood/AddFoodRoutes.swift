import SwiftUI
import SwiftData

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

/// The New-product modal. With the save toggle on the form saves and dismisses
/// itself (no immediate log — the product is then logged from the list, user
/// decision 2026-07-14); it only continues here for log-once entries.
struct NewProductLogSheet: View {
    @Environment(\.modelContext) private var context

    let route: NewProductRoute
    let dayKey: String
    let onLogged: () -> Void

    var body: some View {
        NavigationStack {
            NewProductForm(mode: .logging,
                           prefill: route.prefill,
                           prefillBarcode: route.barcode,
                           onContinue: logOnce)
        }
    }

    /// Log once: the form's values are already "what was eaten", so write them
    /// as-is — the "Per" base amount arrives via `lastQuantity` (canonical g / ml).
    private func logOnce(_ food: LoggableFood) {
        Haptics.success()
        DiaryLogger.log(food, quantity: food.lastQuantity ?? 100, dayKey: dayKey, in: context)
        onLogged()
    }
}
