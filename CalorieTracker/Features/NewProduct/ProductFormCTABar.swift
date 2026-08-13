import SwiftUI

/// Pinned bottom CTA of the product form: a 54pt accentStrong button sitting
/// directly on the page background — no separating bar or hairline.
struct ProductFormCTABar: View {
    let title: LocalizedStringKey
    let enabled: Bool
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
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentColumn()
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppBackground()
        ProductFormCTABar(title: "Add & log", enabled: true, action: {})
    }
}
