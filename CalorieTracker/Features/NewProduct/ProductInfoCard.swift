import SwiftUI

/// Top card of the product form: "Name" text field and the "Per" row with an
/// editable base amount and the mini g/ml segmented control. Storage stays
/// canonical per-100 — entered values are normalized on save (user decision
/// 2026-07-14), the base amount here only sets what the fields below mean.
struct ProductInfoCard: View {
    @Binding var name: String
    @Binding var basis: Basis
    @Binding var perAmountText: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Name")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 88, alignment: .leading)
                TextField("e.g. Homemade soup", text: $name)
                    .font(.callout)
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ProductFormHairline()

            HStack(spacing: 12) {
                Text("Per")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 88, alignment: .leading)
                TextField("100", text: $perAmountText)
                    .keyboardType(.numberPad)
                    .numericInputLimit($perAmountText)
                    .font(.callout)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                BasisSegmentControl(basis: $basis)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
    }
}

/// Mini segmented g / ml control from the prototype: controlFill container
/// (radius 9, padding 2), selected segment white with a subtle shadow.
private struct BasisSegmentControl: View {
    @Binding var basis: Basis

    var body: some View {
        HStack(spacing: 0) {
            segment("g", value: .per100g)
            segment("ml", value: .per100ml)
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Theme.controlFill)
        )
    }

    private func segment(_ label: LocalizedStringKey, value: Basis) -> some View {
        let selected = basis == value
        return Button {
            basis = value
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? Theme.textPrimary : Theme.textSecondary)
                .padding(.vertical, 5)
                .padding(.horizontal, 13)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.12), radius: 1, y: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        AppBackground()
        ProductInfoCard(name: .constant(""), basis: .constant(.per100g),
                        perAmountText: .constant("100"))
            .padding(20)
    }
}
