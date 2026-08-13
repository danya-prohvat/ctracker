import SwiftUI
import SwiftData

/// "Add food" page (spec §5): pinned search, Recent chips, New product /
/// Scan cards and the "My products" list. Presented from the day screen in
/// its own NavigationStack — full-screen cover on Today, card sheet from a
/// calendar day detail (see AddFoodPresentation); the quantity and
/// new-product steps are presented modally (see AddFoodRoutes).
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

    // List ordering and filtering live in AddFoodProductFiltering.swift; the
    // raw query order (nil `lastLoggedAt` last) still serves the Recent chips.
    private var filteredProducts: [Product] {
        products.byRecentActivity.matching(search)
    }

    private var recentProducts: [Product] { products.recentlyLogged }

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
            .sheet(item: $addSheet, onDismiss: popIfNeeded) {
                addStep($0.kind)
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingProduct) { product in
                NavigationStack { NewProductForm(mode: .editing(product)) }
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $creatingProduct) {
                NavigationStack { NewProductForm(mode: .saving) }
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .fullScreenCover(isPresented: $showScanner, onDismiss: presentPendingScan) { scanFlow }
            .confirmDeleteProduct($productToDelete, onConfirm: delete)
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
            NewProductLogSheet(route: route, dayKey: dayKey, onLogged: logFinished)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !recentProducts.isEmpty && search.isEmpty {
                    // Full-bleed so the chips clip at the screen edge (and peek)
                    // instead of at the 20 pt margin; the row insets itself to align.
                    AddFoodRecentsRow(products: recentProducts, unitSystem: unitSystem) { log($0) }
                        .padding(.bottom, 16)
                }
                VStack(alignment: .leading, spacing: 0) {
                    AddFoodActionCards(
                        onNewProduct: { addSheet = AddSheet(kind: .newProduct(NewProductRoute())) },
                        onScan: startScan
                    )
                    .padding(.bottom, 16)
                    AddFoodProductList(
                        products: filteredProducts,
                        searchQuery: search.trimmingCharacters(in: .whitespaces),
                        unitSystem: unitSystem,
                        onSelect: { log($0) },
                        onEdit: { editingProduct = $0 },
                        onDelete: { productToDelete = $0 },
                        onCreate: { creatingProduct = true }
                    )
                    if let settings {
                        AdBannerView(settings: settings)
                            .padding(.top, 14)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
            // Recents stay full-bleed within the column: on iPad the chips
            // clip at the column edge instead of the screen edge.
            .contentColumn()
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

#Preview("RTL ar") {
    NavigationStack {
        AddFoodSheet(dayKey: DayKey.today)
    }
    .modelContainer(PreviewData.container)
    .environment(\.layoutDirection, .rightToLeft)
    .environment(\.locale, Locale(identifier: "ar"))
}
