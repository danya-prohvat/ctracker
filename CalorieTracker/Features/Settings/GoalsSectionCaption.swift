import SwiftUI

/// Uppercase gray section caption above cards (prototype: 13 px semibold,
/// letter-spacing .04em, 6 px inset).
struct GoalsSectionCaption: View {
    private let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .textCase(.uppercase)
            .font(.system(size: 13, weight: .semibold))
            .kerning(0.5)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 6)
    }
}

#Preview {
    ZStack {
        AppBackground()
        GoalsSectionCaption("Daily goals")
    }
}
