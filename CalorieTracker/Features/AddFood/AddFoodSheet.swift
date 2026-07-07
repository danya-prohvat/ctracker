import SwiftUI
import SwiftData

enum AddRoute: Hashable {
    case quantity(LoggableFood)
    case newProduct
    case scanPrefill(LoggableFood, String)   // prefilled from a scan + barcode
    case manualBarcode(String)               // scan not found → empty form with barcode
}

/// "Add food" bottom sheet (spec §5): pinned search, Recent chips, New product /
/// Scan cards and the "My products" list — styled after the approved prototype.
struct AddFoodSheet: View {
    // Internal (not private): AddFoodScanFlow.swift extends this type.
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss

    let dayKey: String

    @Query(sort: [SortDescriptor(\Product.lastLoggedAt, order: .reverse),
                  SortDescriptor(\Product.createdAt, order: .reverse)])
    private var products: [Product]
    @Query private var settingsList: [UserSettings]

    @State var path: [AddRoute] = []
    @State private var search = ""
    @State private var editingProduct: Product?
    @State private var creatingProduct = false
    @State var showScanner = false
    @State var showPaywall = false

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
        NavigationStack(path: $path) {
            content
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AddRoute.self) { destination(for: $0) }
                .sheet(item: $editingProduct) { product in
                    NavigationStack { NewProductForm(mode: .editing(product)) }
                }
                .sheet(isPresented: $creatingProduct) {
                    NavigationStack { NewProductForm(mode: .saving) }
                }
                .sheet(isPresented: $showPaywall) { PaywallView() }
                .fullScreenCover(isPresented: $showScanner) { scanFlow }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(26)
        .presentationBackground(.thinMaterial)
        .presentationDragIndicator(.visible)
        .task {
            #if DEBUG
            // Launch with `-initialAddRoute new|scan|qty` to jump into a subscreen.
            switch UserDefaults.standard.string(forKey: "initialAddRoute") {
            case "new": path.append(.newProduct)
            case "scan": showScanner = true
            case "qty": if let product = products.first { path.append(.quantity(product.loggable)) }
            default: break
            }
            #endif
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            header
            AddFoodSearchField(text: $search)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !recentProducts.isEmpty && search.isEmpty {
                        AddFoodRecentsRow(products: recentProducts) { log($0) }
                            .padding(.top, 4)
                            .padding(.bottom, 16)
                    }
                    AddFoodActionCards(
                        onNewProduct: { path.append(.newProduct) },
                        onScan: startScan
                    )
                    .padding(.bottom, 16)
                    AddFoodProductList(
                        products: filteredProducts,
                        searchQuery: search.trimmingCharacters(in: .whitespaces),
                        onSelect: { log($0) },
                        onEdit: { editingProduct = $0 },
                        onDelete: { delete($0) },
                        onCreate: { creatingProduct = true }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Add food")
                .font(.system(size: 22, weight: .bold))
                .kerning(-0.4)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button("Cancel") { dismiss() }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.accentLabel)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func destination(for route: AddRoute) -> some View {
        switch route {
        case .quantity(let food):
            QuantityLogView(food: food, dayKey: dayKey, unitSystem: unitSystem,
                            onLogged: { dismiss() })
        case .newProduct:
            NewProductForm(mode: .logging,
                           onContinue: { food in path.append(.quantity(food)) })
        case .scanPrefill(let food, let barcode):
            NewProductForm(mode: .logging, prefill: food, prefillBarcode: barcode,
                           onContinue: { food in path.append(.quantity(food)) })
        case .manualBarcode(let barcode):
            NewProductForm(mode: .logging, prefillBarcode: barcode,
                           onContinue: { food in path.append(.quantity(food)) })
        }
    }

    // MARK: - Actions (scan wiring lives in AddFoodScanFlow.swift)

    private func log(_ product: Product) {
        path.append(.quantity(product.loggable))
    }

    private func delete(_ product: Product) {
        // Deleting a product removes it from the database; history stays intact
        // because diary entries carry their own snapshot (spec §2.1).
        context.delete(product)
        try? context.save()
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddFoodSheet(dayKey: DayKey.today)
        }
        .modelContainer(PreviewData.container)
}
