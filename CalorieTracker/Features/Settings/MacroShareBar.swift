import SwiftUI

/// Thin share bar under a macro row ("30% of calories"): track in
/// `Theme.barTrack`, fill in the macro color, leading-aligned so it mirrors
/// under RTL with the row text.
struct MacroShareBar: View {
    var fraction: Double
    var color: Color

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.barTrack)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * clamped)
            }
        }
        .frame(height: 4)
        .animation(.snappy(duration: 0.4), value: clamped)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 12) {
            MacroShareBar(fraction: 0.3, color: Theme.protein)
            MacroShareBar(fraction: 0.3, color: Theme.fat)
            MacroShareBar(fraction: 0.4, color: Theme.carbs)
        }
        .padding(20)
    }
}
