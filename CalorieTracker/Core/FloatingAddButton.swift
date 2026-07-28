import SwiftUI

/// Floating "+" button (62 pt): brand-green vertical gradient circle
/// (`Theme.fabTop` → `fabBottom`) with an SF Symbol plus and a soft tinted
/// shadow; squeezes down while pressed.
struct FloatingAddButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background {
                    Circle()
                        .fill(LinearGradient(colors: [Theme.fabTop, Theme.fabBottom],
                                             startPoint: .top, endPoint: .bottom))
                        .shadow(color: Theme.fabShadow.opacity(0.35), radius: 10, y: 6)
                }
        }
        .buttonStyle(.pressableScale)
        .accessibilityLabel("Add food")
    }
}

#Preview {
    ZStack {
        AppBackground()
        FloatingAddButton {}
    }
}
