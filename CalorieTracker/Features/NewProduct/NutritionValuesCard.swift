import SwiftUI

/// "NUTRITION (PER X G/ML)" caption plus the glass card with the four
/// macro input rows (Calories / Protein / Fat / Carbs). The caption follows
/// the form's editable "Per" amount so the fields' meaning stays obvious.
struct NutritionValuesCard: View {
    let basis: Basis
    let perAmount: Double
    @Binding var calories: String
    @Binding var protein: String
    @Binding var fat: String
    @Binding var carbs: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Nutrition (per \(Format.amount(perAmount)) \(basis.canonicalUnit.label))")
                .textCase(.uppercase)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .padding(EdgeInsets(top: 6, leading: 4, bottom: 10, trailing: 4))

            VStack(spacing: 0) {
                ProductFieldRow(label: Text("Calories"), text: $calories, unit: Text("kcal"))
                ProductFormHairline()
                ProductFieldRow(label: Text("Protein"), text: $protein, unit: Text("g"))
                ProductFormHairline()
                ProductFieldRow(label: Text("Fat"), text: $fat, unit: Text("g"))
                ProductFormHairline()
                ProductFieldRow(label: Text("Carbs"), text: $carbs, unit: Text("g"))
            }
            .glassCard(cornerRadius: Theme.cornerRadius)
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        NutritionValuesCard(basis: .per100g,
                            perAmount: 100,
                            calories: .constant(""),
                            protein: .constant(""),
                            fat: .constant(""),
                            carbs: .constant(""))
            .padding(20)
    }
}
