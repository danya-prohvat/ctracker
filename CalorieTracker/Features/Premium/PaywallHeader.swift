import SwiftUI

/// Paywall hero: app icon badge, headline and subline.
struct PaywallHeader: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie.fill")
                .font(.largeTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.fabTop, Theme.fabBottom],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 74, height: 74)
                .background(Circle().fill(Theme.accentSoft))
            Text("Unlock the full nutrition picture")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("Go beyond calories and macros with Premium.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}
