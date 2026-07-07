import SwiftUI

/// The green gradient "+" FAB from the prototype (62 pt, glossy inner highlight).
struct FloatingAddButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.fabTop, Theme.fabBottom],
                            startPoint: UnitPoint(x: 0.2, y: 0),
                            endPoint: UnitPoint(x: 0.75, y: 1)
                        )
                    )
                    .overlay(
                        Circle().strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.55), Color.white.opacity(0)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                    )
                    .shadow(color: Theme.fabBottom.opacity(0.6), radius: 12, y: 9)
                Text(verbatim: "+")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white)
                    .offset(y: -1.5)
            }
            .frame(width: 62, height: 62)
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
