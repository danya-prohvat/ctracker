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
    @State private var perAmountText = "100"
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

    /// Editable "Per" base amount; the nutrition fields mean "per this many
    /// g/ml". nil while empty/zero — submit stays disabled.
    private var perAmount: Double? {
        guard let value = Format.parse(perAmountText), value > 0 else { return nil }
        return value
    }

    /// Storage is canonical per-100 (spec §3): entered values are multiplied
    /// by this on save.
    private var per100Factor: Double { 100 / (perAmount ?? 100) }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && caloriesValue != nil && perAmount != nil
    }

    private var isDirty: Bool {
        !name.isEmpty || !caloriesText.isEmpty || !proteinText.isEmpty
            || !fatText.isEmpty || !carbsText.isEmpty
            || perAmountText != "100"
            || microTexts.values.contains { !$0.isEmpty }
    }

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
        ProductFormContent(name: $name,
                           basis: $basis,
                           perAmountText: $perAmountText,
                           perAmount: perAmount,
                           caloriesText: $caloriesText,
                           proteinText: $proteinText,
                           fatText: $fatText,
                           carbsText: $carbsText,
                           microTexts: $microTexts,
                           saveToMyProducts: $saveToMyProducts,
                           barcode: barcode,
                           showsSaveToggle: isLogging,
                           showsMissingNutritionNotice: scanFoundButEmpty)
            .background(AppBackground())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ProductFormCTABar(title: primaryTitle, enabled: canSubmit) { submit() }
            }
            .detailNavBar(
                backLabel: Text("Back"),
                title: isEditing ? Text("Edit product") : Text("New product"),
                onBack: { if isDirty { showDiscard = true } else { cancel() } }
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
            if let value = Format.parse(text), value > 0 { out[id] = value * per100Factor }
        }
        return out
    }

    private func makeValues() -> (cals: Double, p: Double, f: Double, c: Double) {
        ((caloriesValue ?? 0) * per100Factor,
         (Format.parse(proteinText) ?? 0) * per100Factor,
         (Format.parse(fatText) ?? 0) * per100Factor,
         (Format.parse(carbsText) ?? 0) * per100Factor)
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
            // Upsert by barcode — scanning the same product twice must never
            // create a twin (CloudKit rules forbid a unique constraint).
            _ = ProductStore.upsert(name: trimmedName, basis: basis,
                                    calories: v.cals, protein: v.p, fat: v.f, carbs: v.c,
                                    micros: micros, barcode: barcode, in: context)
            dismiss()

        case .logging:
            if saveToMyProducts {
                // Save only (user decision 2026-07-14): no immediate quantity
                // step — the product lands in My products and is logged by
                // tapping it in the list.
                _ = ProductStore.upsert(name: trimmedName, basis: basis,
                                        calories: v.cals, protein: v.p, fat: v.f, carbs: v.c,
                                        micros: micros, barcode: barcode, in: context)
                dismiss()
            } else {
                // lastQuantity = the entered base amount, so the immediate
                // log-once writes exactly the values the user typed.
                let food = LoggableFood(
                    productID: nil, name: trimmedName, basis: basis,
                    per100Calories: v.cals, per100Protein: v.p,
                    per100Fat: v.f, per100Carbs: v.c,
                    per100Micros: micros, lastQuantity: perAmount,
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
