import SwiftUI

/// Uppercase section caption inside the Add food sheet (prototype: 13px semibold,
/// uppercase, letter-spacing .04em, #8e8e93).
struct AddFoodCaption: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .kerning(0.5)
            .foregroundStyle(Theme.textSecondary)
            .textCase(.uppercase)
    }
}

#Preview {
    ZStack {
        AppBackground()
        AddFoodCaption(title: "My products")
    }
}
