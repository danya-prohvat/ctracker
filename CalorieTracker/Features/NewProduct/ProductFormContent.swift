import SwiftUI

/// Scrollable body of the product form: barcode chip, name/per card, macro
/// card, vitamins & minerals card and the optional "Save to My products" card.
/// Pure layout — all state lives in `NewProductForm`.
struct ProductFormContent: View {
    @Binding var name: String
    @Binding var basis: Basis
    @Binding var caloriesText: String
    @Binding var proteinText: String
    @Binding var fatText: String
    @Binding var carbsText: String
    @Binding var microTexts: [String: String]
    @Binding var saveToMyProducts: Bool
    let barcode: String?
    let showsSaveToggle: Bool
    /// Scan matched a product, but its card carried no nutrition values.
    var showsMissingNutritionNotice: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let barcode {
                    SavedBarcodeChip(code: barcode)
                        .padding(.bottom, 14)
                }

                if showsMissingNutritionNotice {
                    MissingNutritionNotice()
                        .padding(.bottom, 14)
                }

                ProductInfoCard(name: $name, basis: $basis)
                    .padding(.bottom, 16)

                NutritionValuesCard(basis: basis,
                                    calories: $caloriesText,
                                    protein: $proteinText,
                                    fat: $fatText,
                                    carbs: $carbsText)
                    .padding(.bottom, 16)

                MicroFieldsSection(microTexts: $microTexts)

                if showsSaveToggle {
                    SaveToggleCard(isOn: $saveToMyProducts)
                        .padding(.top, 16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    ZStack {
        AppBackground()
        ProductFormContent(name: .constant(""),
                           basis: .constant(.per100g),
                           caloriesText: .constant(""),
                           proteinText: .constant(""),
                           fatText: .constant(""),
                           carbsText: .constant(""),
                           microTexts: .constant([:]),
                           saveToMyProducts: .constant(true),
                           barcode: "4820000123456",
                           showsSaveToggle: true)
    }
    .modelContainer(PreviewData.container)
}
