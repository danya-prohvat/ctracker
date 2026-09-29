import SwiftUI

/// The scanned code as a translucent pill with a tiny barcode glyph, shown
/// under the not-found message in the dark scan flow.
struct ScanCodeChip: View {
    let code: String

    var body: some View {
        HStack(spacing: 8) {
            ScanBarcodeGlyph(barWidths: [2, 3, 1, 3, 2, 1], spacing: 2)
                .frame(height: 16)
            Text(verbatim: code)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Theme.scanBackground.ignoresSafeArea()
        ScanCodeChip(code: "4820000123456")
    }
}
