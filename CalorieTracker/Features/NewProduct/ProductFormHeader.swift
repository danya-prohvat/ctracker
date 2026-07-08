import SwiftUI

/// Sheet header in native nav-bar style: SF chevron + "Back" in accentLabel,
/// centered title, empty right slot of matching width. The system navigation
/// bar is hidden by the hosting screen.
struct ProductFormHeader: View {
    let title: LocalizedStringKey
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.backward")
                        .font(.body.weight(.semibold))
                    Text("Back")
                        .font(.body)
                }
                .foregroundStyle(Theme.accentLabel)
            }
            .buttonStyle(.plain)
            Spacer()
            Color.clear
                .frame(width: 40, height: 1)
        }
        .overlay {
            Text(title)
                .font(.headline)
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
