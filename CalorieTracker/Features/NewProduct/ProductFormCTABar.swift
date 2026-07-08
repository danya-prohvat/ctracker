import SwiftUI

/// Pinned bottom CTA of the product form: 54pt accentStrong button over a
/// frosted bar with a hairline top border (prototype sheet footer).
struct ProductFormCTABar: View {
    let title: LocalizedStringKey
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ProductFormHairline()
            Button(action: action) {
                Text(title)
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                            .fill(Theme.accentStrong)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.5)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(.thinMaterial)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppBackground()
        ProductFormCTABar(title: "Add & log", enabled: true, action: {})
    }
}
