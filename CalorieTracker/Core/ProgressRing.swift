import SwiftUI

/// Circular progress ring used across Today, Calendar and Goals:
/// a light track plus a round-capped arc starting at 12 o'clock.
struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat
    var color: Color = Theme.accent
    var trackColor: Color = Theme.ringTrack

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .padding(lineWidth / 2)
        .animation(.snappy, value: clamped)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 30) {
            ProgressRing(progress: 0.72, lineWidth: 12)
                .frame(width: 132, height: 132)
            HStack(spacing: 24) {
                ProgressRing(progress: 0.5, lineWidth: 6, color: Theme.protein)
                    .frame(width: 68, height: 68)
                ProgressRing(progress: 0.8, lineWidth: 6, color: Theme.fat)
                    .frame(width: 68, height: 68)
                ProgressRing(progress: 0.3, lineWidth: 6, color: Theme.carbs)
                    .frame(width: 68, height: 68)
            }
        }
    }
}
