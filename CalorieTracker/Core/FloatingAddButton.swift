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
        .buttonStyle(PressableScaleStyle())
        .accessibilityLabel("Add food")
    }
}

/// Scales the label down while pressed — the native "squishy" button feel.
private struct PressableScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        AppBackground()
        FloatingAddButton {}
    }
}
