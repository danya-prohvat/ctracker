import SwiftUI

/// Prototype-style sheet header: "‹ Back" in accentLabel, centered title,
/// empty right slot of matching width. The system navigation bar is hidden
/// by the hosting screen.
struct ProductFormHeader: View {
    let title: LocalizedStringKey
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Text("‹ Back")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.accentLabel)
            }
            .buttonStyle(.plain)
            Spacer()
            Color.clear
                .frame(width: 40, height: 1)
        }
        .overlay {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

#Preview {
    ZStack(alignment: .top) {
        AppBackground()
        ProductFormHeader(title: "New product", onBack: {})
    }
}
