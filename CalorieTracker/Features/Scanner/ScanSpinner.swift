import SwiftUI

/// Prototype lookup spinner: a 34pt ring with a white-18% track and a
/// rotating green arc (0.8s linear, repeating).
struct ScanSpinner: View {
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.18), lineWidth: 3)
            Circle()
                .trim(from: 0, to: 0.24)
                .stroke(Theme.scanLine, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(isSpinning ? 270 : -90))
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                isSpinning = true
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.scanBackground.ignoresSafeArea()
        ScanSpinner()
    }
}
