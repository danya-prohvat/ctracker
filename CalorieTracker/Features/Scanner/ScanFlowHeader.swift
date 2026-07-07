import SwiftUI

/// Header of the dark scan flow: "‹ Back" on the leading edge and a centered
/// "Scan barcode" title, per the prototype.
struct ScanFlowHeader: View {
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text("Scan barcode")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 15, weight: .medium))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
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
