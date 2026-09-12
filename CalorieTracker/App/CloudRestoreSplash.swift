import SwiftUI

/// Full-screen splash shown for the second or two while `CloudRestoreProbe`
/// asks CloudKit whether this iCloud account already has app data (reinstall
/// path). Covers the empty Today so a returning user never sees onboarding
/// flash before their data streams back in.
struct CloudRestoreSplash: View {
    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                Text("Checking iCloud…")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    CloudRestoreSplash()
}
