import SwiftUI

/// Floating capsule tab bar with native SF Symbol icons and standard
/// selected/unselected tinting (accent vs. secondary, no dimming). Icons
/// bounce on selection with a light selection haptic.
struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            tab(.today, label: "Today", symbol: "list.bullet")
            tab(.calendar, label: "Calendar", symbol: "calendar")
            tab(.settings, label: "Settings", symbol: "gearshape")
        }
        // iPad: keep the capsule compact instead of spanning the screen. The
        // cap sits above the widest iPhone layout (376 pt), so no-op there.
        // Not `.contentColumn` — the capsule background must wrap the capped
        // bar, and that modifier would re-expand the view first.
        .frame(maxWidth: 380)
        .frame(height: 64)
        .glassCapsuleBackground()
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func tab(_ tab: AppTab, label: LocalizedStringKey, symbol: String) -> some View {
        let isSelected = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.title3.weight(.medium))
                    .symbolVariant(isSelected ? .fill : .none)
                    .symbolEffect(.bounce, value: isSelected)
                    .frame(height: 24)
                Text(label)
                    .font(.caption2.weight(isSelected ? .semibold : .medium))
                    .ctaFit()
            }
            .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    /// Liquid Glass capsule on iOS 26+, `.ultraThinMaterial` fallback below.
    @ViewBuilder
    func glassCapsuleBackground() -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.interactive(), in: .capsule)
                .shadow(color: Color.black.opacity(0.10), radius: 14, y: 6)
        } else {
            self.background {
                let shape = Capsule()
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(shape.strokeBorder(Theme.separator, lineWidth: 0.5))
                    .shadow(color: Color.black.opacity(0.12), radius: 16, y: 8)
            }
        }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppBackground()
        FloatingTabBar(selection: .constant(.today))
            .padding(.horizontal, 32)
            .padding(.bottom, 8)
    }
}
