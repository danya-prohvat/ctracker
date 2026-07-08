import SwiftUI

/// Flat, native-style backdrop (Health/Fitness look): the light grouped-gray
/// base from `Theme.background`. Kept as a view so the backdrop stays a
/// single point of change across all screens.
struct AppBackground: View {
    var body: some View {
        Theme.background
            .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}
