import SwiftUI

/// The 54 pt accentStrong CTA of the product-style forms — shared by the
/// inline form actions (`ProductFormActions`) and the pinned bar the goals
/// calculator still uses (`ProductFormCTABar`).
struct ProductFormPrimaryButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.bold())
                .foregroundStyle(.white)
                .ctaFit()
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                        .fill(Theme.accentStrong)
                )
        }
        .buttonStyle(.pressableCard)
    }
}

#Preview {
    ZStack {
        AppBackground()
        ProductFormPrimaryButton(title: "Save", action: {})
            .padding(20)
    }
}
