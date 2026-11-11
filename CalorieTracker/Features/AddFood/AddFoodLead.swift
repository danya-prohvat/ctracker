import SwiftUI

/// Where the add flow opens (user decision 2026-11-11). The Today empty
/// state offers "Scan a barcode" and "Add food" one tap away; presenting the
/// list first and the step over it a moment later flashed the list, so the
/// lead step renders in place of the list and hands over to it when done.
enum AddFoodStart {
    case list
    case scanner
    case newProduct
}

/// The step `AddFoodSheet` currently shows: the scanner, the new-product
/// form, or the regular list page.
enum AddFoodLead {
    case scanner
    case newProduct(NewProductRoute)
    case list

    init(_ start: AddFoodStart) {
        switch start {
        case .list: self = .list
        case .scanner: self = .scanner
        case .newProduct: self = .newProduct(NewProductRoute())
        }
    }

    var isScanner: Bool {
        if case .scanner = self { return true }
        return false
    }
}

extension AddFoodSheet {
    /// New-product form as the lead step. Save lands on the list, where the
    /// product is logged by tapping it (user decision 2026-07-14 stays);
    /// log-once closes the whole flow; Back dismisses to the day screen.
    func leadForm(_ route: NewProductRoute) -> some View {
        NewProductForm(mode: .logging,
                       prefill: route.prefill,
                       prefillBarcode: route.barcode,
                       dayKey: dayKey,
                       onContinue: { food in
                           NewProductLogSheet.logOnce(food, dayKey: dayKey, in: context)
                           logFinished()
                       },
                       onSaved: showList)
    }

    /// Scanner outcome while the scanner is the lead step: a new product
    /// continues in the form in place; a product already in the base goes to
    /// the quantity sheet over the list.
    func finishLeadScan(with kind: AddSheet.Kind) {
        switch kind {
        case .newProduct(let route):
            withAnimation(.easeInOut(duration: 0.25)) { lead = .newProduct(route) }
        case .quantity:
            showList()
            // Next run-loop turn: let the list mount before presenting over it.
            Task { @MainActor in addSheet = AddSheet(kind: kind) }
        }
    }

    func showList() {
        withAnimation(.easeInOut(duration: 0.25)) { lead = .list }
    }

    func applyDebugRoute() {
        #if DEBUG
        // Launch with `-initialAddRoute new|scan|qty` to jump into a substep.
        switch UserDefaults.standard.string(forKey: "initialAddRoute") {
        case "new": addSheet = AddSheet(kind: .newProduct(NewProductRoute()))
        case "scan": showScanner = true
        case "qty": if let product = products.first { addSheet = AddSheet(kind: .quantity(product.loggable)) }
        default: break
        }
        #endif
    }
}
