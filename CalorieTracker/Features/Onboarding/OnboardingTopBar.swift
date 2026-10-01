import SwiftUI

/// Onboarding top bar: Back chevron (hidden on the first step and the timed
/// calculating interlude), thin progress bar and the small Skip.
struct OnboardingTopBar: View {
    /// 0...1 share of the flow already reached.
    let progress: Double
    let canGoBack: Bool
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if canGoBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.backward")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 32, height: 32, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressableScale)
                .accessibilityLabel("Back")
                .transition(.opacity)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.separator)
                    Capsule()
                        .fill(Theme.accent)
                        .frame(width: max(8, geo.size.width * progress))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)

            Button("Skip", action: onSkip)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(minHeight: 32)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .contentColumn()
    }
}
