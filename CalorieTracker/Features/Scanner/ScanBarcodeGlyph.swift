import SwiftUI

/// Decorative barcode glyph — a row of white vertical bars stretching to the
/// parent's height. Used in the viewfinder placeholder and the not-found chip.
struct ScanBarcodeGlyph: View {
    let barWidths: [CGFloat]
    var spacing: CGFloat = 2

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(barWidths.indices, id: \.self) { index in
                Rectangle()
                    .fill(.white)
                    .frame(width: barWidths[index])
            }
        }
        .accessibilityHidden(true)
    }
}
