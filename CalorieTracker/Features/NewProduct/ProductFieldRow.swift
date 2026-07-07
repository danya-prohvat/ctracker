import SwiftUI

/// One nutrient-input row from the prototype's form cards: fixed-width label,
/// decimal text field with a gray "0" placeholder and a trailing unit caption.
struct ProductFieldRow: View {
    let label: Text
    var labelWidth: CGFloat = 88
    @Binding var text: String
    let unit: Text

    var body: some View {
        HStack(spacing: 12) {
            label
                .font(.system(size: 15))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: labelWidth, alignment: .leading)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .font(.system(size: 16))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
            unit
                .font(.system(size: 14))
                .foregroundStyle(Theme.textQuaternary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Full-width hairline separator between form-card rows.
struct ProductFormHairline: View {
    var body: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(height: 1)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 0) {
            ProductFieldRow(label: Text("Calories"),
                            text: .constant(""),
                            unit: Text("kcal"))
            ProductFormHairline()
            ProductFieldRow(label: Text("Protein"),
                            text: .constant("12"),
                            unit: Text("g"))
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
        .padding(20)
    }
}
