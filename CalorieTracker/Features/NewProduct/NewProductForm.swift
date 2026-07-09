import SwiftUI
import SwiftData

/// New / edit product form (spec §5), styled after the prototype's frosted
/// sheet: custom header, glass field cards and a pinned bottom CTA.
/// Nutrition is entered per 100 g / 100 ml; fields are empty with a gray "0"
/// placeholder (never pre-filled zeros).
struct NewProductForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let mode: ProductFormMode
    var prefill: LoggableFood? = nil          // e.g. from a barcode scan result
    var prefillBarcode: String? = nil         // barcode to attach (scan flow)
    var onContinue: (LoggableFood) -> Void = { _ in }

    @State private var name = ""
    @State private var basis: Basis = .per100g
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var fatText = ""
    @State private var carbsText = ""
    @State private var microTexts: [String: String] = [:]
    @State private var saveToMyProducts = true
    @State private var barcode: String? = nil

    @State private var didLoad = false
    @State private var showDiscard = false

    private var isLogging: Bool { if case .logging = mode { return true }; return false }
    private var isEditing: Bool { if case .editing = mode { return true }; return false }

    private var caloriesValue: Double? { Format.parse(caloriesText) }
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && caloriesValue != nil
    }

    private var isDirty: Bool {
        !name.isEmpty || !caloriesText.isEmpty || !proteinText.isEmpty
            || !fatText.isEmpty || !carbsText.isEmpty
            || microTexts.values.contains { !$0.isEmpty }
    }

    private var primaryTitle: LocalizedStringKey {
        switch mode {
        case .logging: return saveToMyProducts ? "Add & log" : "Log once"
        case .saving, .editing: return "Save"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ProductFormHeader(title: isEditing ? "Edit product" : "New product") {
                if isDirty { showDiscard = true } else { cancel() }
            }
            ProductFormContent(name: $name,
                               basis: $basis,
                               caloriesText: $caloriesText,
                               proteinText: $proteinText,
                               fatText: $fatText,
                               carbsText: $carbsText,
                               microTexts: $microTexts,
                               saveToMyProducts: $saveToMyProducts,
                               barcode: barcode,
                               showsSaveToggle: isLogging)
        }
        .background(AppBackground())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ProductFormCTABar(title: primaryTitle, enabled: canSubmit) { submit() }
        }
        .confirmationDialog("Discard changes?", isPresented: $showDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { cancel() }
            Button("Keep editing", role: .cancel) {}
        }
        .onAppear(perform: loadOnce)
    }

    private func loadOnce() {
        guard !didLoad else { return }
        didLoad = true
        if case .editing(let product) = mode {
            name = product.name
            basis = product.basis
            caloriesText = product.calories == 0 ? "" : Format.editable(product.calories)
            proteinText = product.protein == 0 ? "" : Format.editable(product.protein)
            fatText = product.fat == 0 ? "" : Format.editable(product.fat)
            carbsText = product.carbs == 0 ? "" : Format.editable(product.carbs)
            microTexts = product.micros.mapValues { Format.editable($0) }
            barcode = product.barcode
        } else if let prefill {
            name = prefill.name
            basis = prefill.basis
            caloriesText = prefill.per100Calories == 0 ? "" : Format.editable(prefill.per100Calories)
            proteinText = prefill.per100Protein == 0 ? "" : Format.editable(prefill.per100Protein)
            fatText = prefill.per100Fat == 0 ? "" : Format.editable(prefill.per100Fat)
            carbsText = prefill.per100Carbs == 0 ? "" : Format.editable(prefill.per100Carbs)
            microTexts = prefill.per100Micros.mapValues { Format.editable($0) }
        }
        if let prefillBarcode { barcode = prefillBarcode }
    }

    /// Parse the micro fields into per-100 values, dropping empty/invalid input.
    private func parsedMicros() -> [String: Double] {
        var out: [String: Double] = [:]
        for (id, text) in microTexts {
            if let value = Format.parse(text), value > 0 { out[id] = value }
        }
        return out
    }

    private func makeValues() -> (cals: Double, p: Double, f: Double, c: Double) {
        (caloriesValue ?? 0,
         Format.parse(proteinText) ?? 0,
         Format.parse(fatText) ?? 0,
         Format.parse(carbsText) ?? 0)
    }

    private func submit() {
        let v = makeValues()
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        let micros = parsedMicros()

        switch mode {
        case .editing(let product):
            product.name = trimmedName
            product.basis = basis
            product.calories = v.cals
            product.protein = v.p
            product.fat = v.f
            product.carbs = v.c
            product.micros = micros
            try? context.save()
            dismiss()

        case .saving:
            let product = Product(name: trimmedName, basis: basis,
                                  calories: v.cals, protein: v.p, fat: v.f, carbs: v.c,
                                  micros: micros, barcode: barcode)
            context.insert(product)
            try? context.save()
            dismiss()

        case .logging:
            if saveToMyProducts {
                let product = Product(name: trimmedName, basis: basis,
                                      calories: v.cals, protein: v.p, fat: v.f, carbs: v.c,
                                      micros: micros, barcode: barcode)
                context.insert(product)
                try? context.save()
                onContinue(product.loggable)
            } else {
                let food = LoggableFood(
                    productID: nil, name: trimmedName, basis: basis,
                    per100Calories: v.cals, per100Protein: v.p,
                    per100Fat: v.f, per100Carbs: v.c,
                    per100Micros: micros, lastQuantity: nil,
                    wasScanned: barcode?.isEmpty == false
                )
                onContinue(food)
            }
        }
    }

    private func cancel() {
        // In logging mode this pops back to the Add-food list; when presented
        // modally (saving/editing) it dismisses the sheet.
        dismiss()
    }
}

#Preview("Logging") {
    NavigationStack {
        NewProductForm(mode: .logging)
    }
    .modelContainer(PreviewData.container)
}

#Preview("With barcode") {
    NavigationStack {
        NewProductForm(mode: .logging, prefillBarcode: "4820000123456")
    }
    .modelContainer(PreviewData.container)
}
