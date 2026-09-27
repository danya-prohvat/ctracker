import SwiftUI

/// Pinned bottom CTA (goals calculator): the shared primary button sitting
/// directly on the page background — no separating bar or hairline. The
/// product form itself no longer pins its actions (see `ProductFormActions`).
struct ProductFormCTABar: View {
    let title: LocalizedStringKey
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        ProductFormPrimaryButton(title: title, action: action)
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
        ProductFormCTABar(title: "Apply", enabled: true, action: {})
    }
}
