import SwiftUI

/// Header of the dark scan flow: the shared `BackButtonLabel` (white on the
/// camera) on the leading edge and a centered "Scan barcode" title.
struct ScanFlowHeader: View {
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text("Scan barcode")
                .font(.headline)
                .foregroundStyle(.white)
            HStack {
                Button(action: onBack) {
                    BackButtonLabel()
                        .foregroundStyle(.white.opacity(0.9))
                }
                .accessibilityLabel("Back")
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
