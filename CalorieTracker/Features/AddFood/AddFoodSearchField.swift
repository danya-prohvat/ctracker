import SwiftUI

/// Pinned search field of the Add food sheet: grey control fill, radius 12,
/// magnifier + 16pt text field (prototype padding 9/12).
struct AddFoodSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(hex: 0x9A9AA0))
            TextField("Search my products", text: $text)
                .font(.system(size: 16))
                .foregroundStyle(Theme.textPrimary)
                .autocorrectionDisabled()
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusControl, style: .continuous)
                .fill(Theme.controlFill)
        )
    }
}

#Preview {
    ZStack {
        AppBackground()
        AddFoodSearchField(text: .constant(""))
            .padding(20)
    }
}
