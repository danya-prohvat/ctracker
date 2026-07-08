import SwiftUI

/// Header of the dark scan flow: "‹ Back" on the leading edge and a centered
/// "Scan barcode" title, per the prototype.
struct ScanFlowHeader: View {
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text("Scan barcode")
                .font(.headline)
                .foregroundStyle(.white)
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.backward")
                            .font(.subheadline.weight(.medium))
                        Text("Back")
                            .font(.callout.weight(.medium))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }
                .accessibilityLabel(Text("Cancel"))
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    ZStack(alignment: .top) {
        Theme.scanBackground.ignoresSafeArea()
        ScanFlowHeader(onBack: {})
    }
}
