import SwiftUI

/// Floating "+" button (62 pt): flat accent circle with an SF Symbol plus,
/// native style — no gloss, just a soft tinted shadow.
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
                        .fill(Theme.accentStrong)
                        .shadow(color: Theme.accentStrong.opacity(0.35), radius: 10, y: 6)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add food")
    }
}

#Preview {
    ZStack {
        AppBackground()
        FloatingAddButton {}
    }
}
