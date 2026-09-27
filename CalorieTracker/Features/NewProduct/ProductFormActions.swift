import SwiftUI

/// Product-form actions as the LAST block of the scroll content (user
/// decision 2026-09-27, replaces the pinned bar that covered the fields and
/// collided with the keyboard): filled primary plus an optional soft-green
/// secondary ("log once, don't save"). Both follow the same enabled state.
struct ProductFormActions: View {
    let primaryTitle: LocalizedStringKey
    var secondaryTitle: LocalizedStringKey? = nil
    let enabled: Bool
    let onPrimary: () -> Void
    var onSecondary: () -> Void = {}

    var body: some View {
        VStack(spacing: 10) {
            ProductFormPrimaryButton(title: primaryTitle, action: onPrimary)
            if let secondaryTitle {
                Button(action: onSecondary) {
                    Text(secondaryTitle)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.accentDeep)
                        .ctaFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                                .fill(Theme.accentSoft)
                        )
                }
                .buttonStyle(.pressableCard)
            }
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
    }
}

#Preview {
    ZStack {
        AppBackground()
        ProductFormActions(primaryTitle: "Save to My products",
                           secondaryTitle: "Log today only",
                           enabled: true, onPrimary: {}, onSecondary: {})
            .padding(20)
    }
}
