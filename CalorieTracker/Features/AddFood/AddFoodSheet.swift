import SwiftUI
import SwiftData

/// "Add food" page (spec §5): pinned search, Recent chips, New product /
/// Scan cards and the "My products" list. Pushed from the day screen; the
/// quantity and new-product steps are presented modally (see AddFoodRoutes).
struct AddFoodSheet: View {
    // Internal (not private): AddFoodScanFlow.swift extends this type.
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss

    let dayKey: String

    @Query(sort: [SortDescriptor(\Product.lastLoggedAt, order: .reverse),
                  SortDescriptor(\Product.createdAt, order: .reverse)])
    private var products: [Product]
    @Query private var settingsList: [UserSettings]

    @State private var search = ""
    @State private var editingProduct: Product?
    @State private var productToDelete: Product?
    @State private var creatingProduct = false
    @State var showScanner = false
    @State var showPaywall = false
    // Set by the scanner, presented once its cover finishes dismissing.
    @State var pendingScan: AddSheet.Kind?
    @State private var addSheet: AddSheet?
    @State private var popAfterSheet = false

    var settings: UserSettings? { settingsList.first }
    private var unitSystem: UnitSystem { settings?.unitSystem ?? .metric }

    private var filteredProducts: [Product] {
        let q = search.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return products }
        return products.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    /// Last 8 distinct logged products (spec §5).
    private var recentProducts: [Product] {
        products.filter { $0.lastLoggedAt != nil }.prefix(8).map { $0 }
    }

    var body: some View {
        content
            .background(AppBackground())
            .searchable(
                text: $search,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("Search my products")
            )
            .detailNavBar(
                backLabel: Text(dayLabel),
                title: Text("Add food"),
                onBack: { dismiss() }
            )
            .hidesFloatingTabBar()
            .sheet(item: $addSheet, onDismiss: popIfNeeded) { addStep($0.kind) }
            .sheet(item: $editingProduct) { product in
                NavigationStack { NewProductForm(mode: .editing(product)) }
            }
            .sheet(isPresented: $creatingProduct) {
                NavigationStack { NewProductForm(mode: .saving) }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .fullScreenCover(isPresented: $showScanner, onDismiss: presentPendingScan) { scanFlow }
            .alert(
                "Delete product?",
                isPresented: Binding(
                    get: { productToDelete != nil },
                    set: { if !$0 { productToDelete = nil } }
                ),
                presenting: productToDelete
            ) { product in
                Button("Delete", role: .destructive) { delete(product) }
                Button("Cancel", role: .cancel) {}
            } message: { product in
                // Deleting only removes it from My products; past diary entries
                // keep their own snapshot (spec §2.1), so history is untouched.
                Text("“\(product.name)” will be removed from your products. Your logged entries stay.")
            }
            .task { applyDebugRoute() }
    }

    @ViewBuilder
    private func addStep(_ kind: AddSheet.Kind) -> some View {
        switch kind {
        case .quantity(let food):
            NavigationStack {
                QuantityLogView(food: food, dayKey: dayKey,
                                unitSystem: unitSystem, onLogged: logFinished)
            }
        case .newProduct(let route):
            NewProductLogSheet(route: route, dayKey: dayKey,
                               unitSystem: unitSystem, onLogged: logFinished)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !recentProducts.isEmpty && search.isEmpty {
                    AddFoodRecentsRow(products: recentProducts) { log($0) }
                        .padding(.bottom, 16)
                }
                AddFoodActionCards(
                    onNewProduct: { addSheet = AddSheet(kind: .newProduct(NewProductRoute())) },
                    onScan: startScan
                )
                .padding(.bottom, 16)
                AddFoodProductList(
                    products: filteredProducts,
                    searchQuery: search.trimmingCharacters(in: .whitespaces),
                    onSelect: { log($0) },
                    onEdit: { editingProduct = $0 },
                    onDelete: { productToDelete = $0 },
                    onCreate: { creatingProduct = true }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    /// Back label = the day this page was pushed from, e.g. "9 July".
    private var dayLabel: String {
        (DayKey.date(from: dayKey) ?? Date()).formatted(.dateTime.month(.wide).day())
    }

    // MARK: - Actions (scan wiring lives in AddFoodScanFlow.swift)

    private func log(_ product: Product) {
        addSheet = AddSheet(kind: .quantity(product.loggable))
    }

    /// A completed log (or "Close") dismisses the modal, then pops the page.
    private func logFinished() {
        popAfterSheet = true
        addSheet = nil
    }

    private func popIfNeeded() {
        if popAfterSheet {
            popAfterSheet = false
            dismiss()
        }
    }

    /// Present the scan result only after the scanner cover has dismissed, so
    /// the cover→sheet transition doesn't collide.
    private func presentPendingScan() {
        guard let kind = pendingScan else { return }
        pendingScan = nil
        addSheet = AddSheet(kind: kind)
    }

    private func delete(_ product: Product) {
        // Deleting a product removes it from the database; history stays intact
        // because diary entries carry their own snapshot (spec §2.1).
        context.delete(product)
        try? context.save()
    }

    private func applyDebugRoute() {
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

#Preview {
    NavigationStack {
        AddFoodSheet(dayKey: DayKey.today)
    }
    .modelContainer(PreviewData.container)
}
