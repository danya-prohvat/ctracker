import SwiftUI

/// Pastel gradient backdrop from the prototype: a soft green bloom top-leading,
/// blue top-trailing and peach at the bottom over a light gray base.
struct AppBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let size = max(proxy.size.width, proxy.size.height)
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0xEEF2F4), Color(hex: 0xECEEF2)],
                    startPoint: .top, endPoint: .bottom
                )
                RadialGradient(
                    colors: [Color(hex: 0xCFF7DC).opacity(0.95), .clear],
                    center: UnitPoint(x: 0.12, y: 0.04),
                    startRadius: 0, endRadius: size * 0.62
                )
                RadialGradient(
                    colors: [Color(hex: 0xC8EFFF).opacity(0.9), .clear],
                    center: UnitPoint(x: 0.92, y: 0.12),
                    startRadius: 0, endRadius: size * 0.58
                )
                RadialGradient(
                    colors: [Color(hex: 0xFFE8C9).opacity(0.85), .clear],
                    center: UnitPoint(x: 0.5, y: 1.08),
                    startRadius: 0, endRadius: size * 0.62
                )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}
