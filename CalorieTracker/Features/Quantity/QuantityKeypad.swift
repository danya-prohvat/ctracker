import SwiftUI

/// A key on the custom quantity keypad.
enum QuantityKey: Hashable {
    case digit(Int)
    case backspace
}

/// Prototype-style 3-column glass keypad that replaces the system keyboard;
/// whole numbers only (user decision 2026-07-14) — no decimal separator, the
/// bottom-row 0 stretches across two columns with backspace on the right.
struct QuantityKeypad: View {
    let onKey: (QuantityKey) -> Void

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(0..<3) { row in
                GridRow {
                    ForEach(1..<4) { column in
                        keyButton(.digit(row * 3 + column))
                    }
                }
            }
            GridRow {
                keyButton(.digit(0))
                    .gridCellColumns(2)
                keyButton(.backspace)
            }
        }
    }

    private func keyButton(_ key: QuantityKey) -> some View {
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

    @ViewBuilder
    private func keyLabel(for key: QuantityKey) -> some View {
        switch key {
        case .digit(let value):
            Text(verbatim: "\(value)")
                .font(.stat(.title2, .regular))
                .foregroundStyle(Theme.textPrimary)
        case .backspace:
            Image(systemName: "delete.left")
                .font(.stat(.title2, .regular))
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
