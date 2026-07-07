import SwiftUI

/// Soft-green chip shown when the form was reached from the scanner with a
/// barcode attached: tiny barcode glyph, "BARCODE SAVED" caption and the code.
struct SavedBarcodeChip: View {
    let code: String

    /// Bar widths of the decorative barcode glyph (prototype: 2/3/1/3/2/1/3 px).
    private let barWidths: [CGFloat] = [2, 3, 1, 3, 2, 1, 3]

    var body: some View {
        HStack(spacing: 10) {
            glyph
            VStack(alignment: .leading, spacing: 1) {
                Text("Barcode saved")
                    .font(.system(size: 12, weight: .semibold))
                    .textCase(.uppercase)
                    .kerning(0.4)
                    .foregroundStyle(Theme.accentDeep)
                Text(verbatim: code)
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusControl, style: .continuous)
                .fill(Theme.accentSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusControl, style: .continuous)
                .strokeBorder(Color(hex: 0xB4D8C0).opacity(0.6), lineWidth: 0.5)
        )
    }

    private var glyph: some View {
        HStack(spacing: 2) {
            ForEach(barWidths.indices, id: \.self) { index in
                Rectangle()
                    .fill(Theme.fabShadow)
                    .frame(width: barWidths[index])
            }
        }
        .frame(height: 18)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        AppBackground()
        SavedBarcodeChip(code: "4820000123456")
            .padding(20)
    }
}
