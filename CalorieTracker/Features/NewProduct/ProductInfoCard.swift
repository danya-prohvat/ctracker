import SwiftUI

/// Top card of the product form: "Name" text field and the "Per 100" row with
/// the mini g/ml segmented control. Nutrition stays canonical per-100 —
/// the base amount is fixed (spec §1), only the unit toggles.
struct ProductInfoCard: View {
    @Binding var name: String
    @Binding var basis: Basis

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Name")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 88, alignment: .leading)
                TextField("e.g. Homemade soup", text: $name)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ProductFormHairline()

            HStack(spacing: 12) {
                Text("Per")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 88, alignment: .leading)
                Text(Format.amount(100))
                    .font(.system(size: 16))
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
                .font(.system(size: 14, weight: .semibold))
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
        ProductInfoCard(name: .constant(""), basis: .constant(.per100g))
            .padding(20)
    }
}
