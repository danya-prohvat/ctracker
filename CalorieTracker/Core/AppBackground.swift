import SwiftUI

/// "Aurora" backdrop (user decision 2026-07-28, replaces the flat gray look):
/// three large soft color washes — brand green top-leading, cool blue on the
/// trailing edge, warm amber at the bottom — over the neutral base from
/// `Theme.background` (Journal/Invites style). Kept as a view so the backdrop
/// stays a single point of change across all screens.
struct AppBackground: View {
    var body: some View {
        GeometryReader { geo in
            let side = max(geo.size.width, geo.size.height)
            ZStack {
                Theme.background
                wash(Theme.auroraGreen, center: UnitPoint(x: 0.18, y: 0.0), radius: side * 0.40)
                wash(Theme.auroraBlue, center: UnitPoint(x: 1.0, y: 0.30), radius: side * 0.30)
                wash(Theme.auroraWarm, center: UnitPoint(x: 0.5, y: 1.05), radius: side * 0.32)
            }
        }
        .ignoresSafeArea()
    }

    // Fades to the same hue at zero alpha (not `.clear`, which fringes gray).
    private func wash(_ color: Color, center: UnitPoint, radius: CGFloat) -> some View {
        RadialGradient(
            colors: [color, color.opacity(0)],
            center: center,
            startRadius: 0,
            endRadius: radius
        )
    }
}

#Preview {
    AppBackground()
}
