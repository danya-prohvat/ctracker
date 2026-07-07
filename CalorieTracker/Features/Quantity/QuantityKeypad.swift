import SwiftUI

/// A key on the custom quantity keypad.
enum QuantityKey: Hashable, Identifiable {
    case digit(Int)
    case separator
    case backspace

    var id: Self { self }

    /// Prototype layout: 1–9, decimal separator, 0, backspace.
    static let layout: [QuantityKey] = [
        .digit(1), .digit(2), .digit(3),
        .digit(4), .digit(5), .digit(6),
        .digit(7), .digit(8), .digit(9),
        .separator, .digit(0), .backspace
    ]
}

/// Prototype-style 3-column glass keypad that replaces the system keyboard.
/// Shows the locale decimal separator; emits key events to the owner.
struct QuantityKeypad: View {
    let onKey: (QuantityKey) -> Void

    private var separator: String { Locale.current.decimalSeparator ?? "." }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(QuantityKey.layout) { key in
                Button {
                    onKey(key)
                } label: {
                    keyLabel(for: key)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .contentShape(RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous))
                }
                .buttonStyle(.plain)
                .glassCard(cornerRadius: Theme.radiusButton)
            }
        }
    }

    @ViewBuilder
    private func keyLabel(for key: QuantityKey) -> some View {
        switch key {
        case .digit(let value):
            Text(verbatim: "\(value)")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        case .separator:
            Text(verbatim: separator)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        case .backspace:
            Image(systemName: "delete.left")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        QuantityKeypad(onKey: { _ in })
            .padding(20)
    }
}
