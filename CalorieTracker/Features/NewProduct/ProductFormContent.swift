import SwiftUI

/// Scrollable body of the product form: barcode chip, name/per card, macro
/// card, the vitamins & minerals card and the actions block at the end.
/// Pure layout — all state lives in `NewProductForm`.
struct ProductFormContent: View {
    @Binding var name: String
    @Binding var basis: Basis
    @Binding var perAmountText: String
    /// Parsed "Per" amount (nil while invalid) — drives the nutrition caption.
    let perAmount: Double?
    @Binding var caloriesText: String
    @Binding var proteinText: String
    @Binding var fatText: String
    @Binding var carbsText: String
    @Binding var microTexts: [String: String]
    let barcode: String?
    /// Scan matched a product, but its card lacked the name and/or nutrition.
    var scanMissingData: ScanMissingData? = nil
    /// Actions live at the end of the form, not in a pinned bar (user
    /// decision 2026-09-27): nothing covers the fields and the keyboard
    /// simply pushes the content up.
    let primaryTitle: LocalizedStringKey
    var secondaryTitle: LocalizedStringKey? = nil
    let canSubmit: Bool
    let onPrimary: () -> Void
    var onSecondary: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let barcode {
                    SavedBarcodeChip(code: barcode)
                        .padding(.bottom, 14)
                }

                if let scanMissingData {
                    ScanMissingDataNotice(missing: scanMissingData)
                        .padding(.bottom, 14)
                }

                ProductInfoCard(name: $name, basis: $basis,
                                perAmountText: $perAmountText)
                    .padding(.bottom, 16)

                NutritionValuesCard(basis: basis,
                                    perAmount: perAmount ?? 100,
                                    calories: $caloriesText,
                                    protein: $proteinText,
                                    fat: $fatText,
                                    carbs: $carbsText)
                    .padding(.bottom, 16)

                MicroFieldsSection(microTexts: $microTexts)

                ProductFormActions(primaryTitle: primaryTitle,
                                   secondaryTitle: secondaryTitle,
                                   enabled: canSubmit,
                                   onPrimary: onPrimary,
                                   onSecondary: onSecondary)
                    .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
            .contentColumn()
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissesKeyboardOnTap()
    }
}

#Preview {
    ZStack {
        AppBackground()
        ProductFormContent(name: .constant(""),
                           basis: .constant(.per100g),
                           perAmountText: .constant("100"),
                           perAmount: 100,
                           caloriesText: .constant(""),
                           proteinText: .constant(""),
                           fatText: .constant(""),
                           carbsText: .constant(""),
                           microTexts: .constant([:]),
                           barcode: "4820000123456",
                           primaryTitle: "Save to My products",
                           secondaryTitle: "Log today only",
                           canSubmit: true,
                           onPrimary: {})
    }
    .modelContainer(PreviewData.container)
}
