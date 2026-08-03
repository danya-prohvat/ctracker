import SwiftUI
import SwiftData

/// New / edit product form (spec §5), styled after the prototype's frosted
/// sheet: custom header, glass field cards and a pinned bottom CTA.
/// Nutrition is entered per 100 g / 100 ml; fields are empty with a gray "0"
/// placeholder (never pre-filled zeros). Field state and parsing live in
/// `ProductFormFields`; this view is layout, routing and persistence.
struct NewProductForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let mode: ProductFormMode
    var prefill: LoggableFood? = nil          // e.g. from a barcode scan result
    var prefillBarcode: String? = nil         // barcode to attach (scan flow)
    var onContinue: (LoggableFood) -> Void = { _ in }

    @State private var fields = ProductFormFields()
    @State private var saveToMyProducts = true
    @State private var barcode: String? = nil

    @State private var didLoad = false
    @State private var showDiscard = false

    private var isLogging: Bool { if case .logging = mode { return true }; return false }
    private var isEditing: Bool { if case .editing = mode { return true }; return false }

    /// The scanner matched a product whose card has no nutrition values at all
    /// (a half-filled OFF entry) — worth telling the user why fields are empty.
    private var scanFoundButEmpty: Bool {
        guard let prefill, prefill.wasScanned else { return false }
        return prefill.per100Calories == 0 && prefill.per100Protein == 0
            && prefill.per100Fat == 0 && prefill.per100Carbs == 0
            && prefill.per100Micros.isEmpty
    }

    private var primaryTitle: LocalizedStringKey {
        switch mode {
        case .logging: return saveToMyProducts ? "Save" : "Add to today"
        case .saving, .editing: return "Save"
        }
    }

    var body: some View {
        ProductFormContent(name: $fields.name,
                           basis: $fields.basis,
                           perAmountText: $fields.perAmountText,
                           perAmount: fields.perAmount,
                           caloriesText: $fields.caloriesText,
                           proteinText: $fields.proteinText,
                           fatText: $fields.fatText,
                           carbsText: $fields.carbsText,
                           microTexts: $fields.microTexts,
                           saveToMyProducts: $saveToMyProducts,
                           barcode: barcode,
                           showsSaveToggle: isLogging,
                           showsMissingNutritionNotice: scanFoundButEmpty)
            .background(AppBackground())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ProductFormCTABar(title: primaryTitle, enabled: fields.canSubmit) { submit() }
            }
            .detailNavBar(
                backLabel: Text("Back"),
                title: isEditing ? Text("Edit product") : Text("New product"),
                onBack: { if fields.isDirty { showDiscard = true } else { cancel() } }
            )
            .alert("Discard changes?", isPresented: $showDiscard) {
                Button("Keep editing", role: .cancel) {}
                Button("Discard", role: .destructive) { cancel() }
            } message: {
                Text("What you've entered won't be saved.")
            }
            .onAppear(perform: loadOnce)
    }

    private func loadOnce() {
        guard !didLoad else { return }
        didLoad = true
        if case .editing(let product) = mode {
            fields.load(product: product)
            barcode = product.barcode
        } else if let prefill {
            fields.load(prefill: prefill)
        }
        if let prefillBarcode { barcode = prefillBarcode }
    }

    private func submit() {
        let v = fields.macroValues()
        let micros = fields.parsedMicros()
        let trimmedName = fields.trimmedName

        switch mode {
        case .editing(let product):
            product.name = trimmedName
            product.basis = fields.basis
            product.calories = v.cals
            product.protein = v.p
            product.fat = v.f
            product.carbs = v.c
            product.micros = micros
            try? context.save()
            dismiss()

        case .saving:
            // Upsert by barcode — scanning the same product twice must never
            // create a twin (CloudKit rules forbid a unique constraint).
            _ = ProductStore.upsert(name: trimmedName, basis: fields.basis,
                                    calories: v.cals, protein: v.p, fat: v.f, carbs: v.c,
                                    micros: micros, barcode: barcode, in: context)
            dismiss()

        case .logging:
            if saveToMyProducts {
                // Save only (user decision 2026-07-14): no immediate quantity
                // step — the product lands in My products and is logged by
                // tapping it in the list.
                _ = ProductStore.upsert(name: trimmedName, basis: fields.basis,
                                        calories: v.cals, protein: v.p, fat: v.f, carbs: v.c,
                                        micros: micros, barcode: barcode, in: context)
                dismiss()
            } else {
                // lastQuantity = the entered base amount, so the immediate
                // log-once writes exactly the values the user typed.
                let food = LoggableFood(
                    productID: nil, name: trimmedName, basis: fields.basis,
                    per100Calories: v.cals, per100Protein: v.p,
                    per100Fat: v.f, per100Carbs: v.c,
                    per100Micros: micros, lastQuantity: fields.perAmount,
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
