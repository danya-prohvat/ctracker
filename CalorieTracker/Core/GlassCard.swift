import SwiftUI

/// Plain white card on the grouped-gray background — the native inset-grouped
/// look (Health/Fitness). Name kept from the earlier glass styling so call
/// sites stay a single point of change.
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: Theme.cardShadow, radius: 2, y: 1)
            }
    }
}

extension View {
    /// Wraps the view in a standard app card.
    func glassCard(cornerRadius: CGFloat = Theme.radiusCard) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 16) {
            Text(verbatim: "Summary")
                .frame(maxWidth: .infinity)
                .padding(22)
                .glassCard()
            Text(verbatim: "Row card")
                .frame(maxWidth: .infinity)
                .padding(14)
                .glassCard(cornerRadius: Theme.cornerRadius)
        }
        .padding(20)
    }
}
