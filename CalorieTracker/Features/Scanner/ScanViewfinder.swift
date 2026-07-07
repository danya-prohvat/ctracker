import SwiftUI

/// The 240×240 scan viewfinder from the prototype: a rounded camera window
/// with four green corner brackets and an animated sweeping scan line.
///
/// `camera` is the live preview; when it renders nothing (simulator, or the
/// searching state) a subtle gradient placeholder with a faux barcode shows.
struct ScanViewfinder<CameraContent: View>: View {
    @ViewBuilder var camera: CameraContent

    @State private var lineAtBottom = false

    private let side: CGFloat = 240

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.06), .white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            ScanBarcodeGlyph(barWidths: [3, 6, 2, 8, 3, 5, 2, 7, 3, 4], spacing: 4)
                .frame(width: 144, height: 96)
                .opacity(0.5)
            camera
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(alignment: .top) { scanLine }
        .overlay { brackets }
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                lineAtBottom = true
            }
        }
    }

    private var scanLine: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Theme.scanLine)
            .shadow(color: Theme.scanLine.opacity(0.85), radius: 7)
            .frame(height: 2)
            .padding(.horizontal, 8)
            .offset(y: lineAtBottom ? side * 0.86 : side * 0.10)
    }

    private var brackets: some View {
        ZStack {
            bracket(rotation: 0, alignment: .topLeading, dx: -2, dy: -2)
            bracket(rotation: 90, alignment: .topTrailing, dx: 2, dy: -2)
            bracket(rotation: 180, alignment: .bottomTrailing, dx: 2, dy: 2)
            bracket(rotation: 270, alignment: .bottomLeading, dx: -2, dy: 2)
        }
        // Purely decorative and horizontally symmetric — keep physical
        // placement so rotations always match their corners under RTL.
        .environment(\.layoutDirection, .leftToRight)
    }

    private func bracket(
        rotation: Double, alignment: Alignment, dx: CGFloat, dy: CGFloat
    ) -> some View {
        CornerBracketShape()
            .stroke(Theme.scanCorner, lineWidth: 3)
            .frame(width: 34, height: 34)
            .rotationEffect(.degrees(rotation))
            .offset(x: dx, y: dy)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}

/// One top-leading corner bracket (vertical leg → 12pt arc → horizontal leg);
/// the other corners are rotations of this shape.
private struct CornerBracketShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 12
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

#Preview {
    ZStack {
        Theme.scanBackground.ignoresSafeArea()
        ScanViewfinder { EmptyView() }
    }
}
