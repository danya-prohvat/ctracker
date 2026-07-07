import SwiftUI

/// Frosted-glass card from the prototype: rgba(255,255,255,.5) + blur,
/// hairline white border and a soft shadow.
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(shape.fill(Color.white.opacity(0.38)))
                    .overlay(shape.strokeBorder(Color.white.opacity(0.6), lineWidth: 0.5))
                    .shadow(color: Theme.cardShadow, radius: 2, y: 1)
            }
    }
}

extension View {
    /// Wraps the view in a prototype-style glass card.
    func glassCard(cornerRadius: CGFloat = Theme.radiusCard) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 16) {
            Text("Summary")
                .frame(maxWidth: .infinity)
                .padding(22)
                .glassCard()
            Text("Row card")
                .frame(maxWidth: .infinity)
                .padding(14)
                .glassCard(cornerRadius: Theme.cornerRadius)
        }
        .padding(20)
    }
}
