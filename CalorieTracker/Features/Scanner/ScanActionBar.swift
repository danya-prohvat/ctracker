import SwiftUI
import UIKit

/// State-dependent bottom action stack of the dark scan flow: a 54pt green
/// primary button plus a 50pt translucent secondary one, per the prototype.
/// Manual barcode entry is not here — it is a link under the status panel
/// opening `ScanManualEntrySheet` (user decision 2026-09-28).
struct ScanActionBar: View {
    let phase: ScanFlowPhase
    let onCreateManually: (String) -> Void
    let onScanAgain: () -> Void
    let onRetry: (String) -> Void
    /// Opt-in rewarded ad: the found product is revealed after it.
    let onWatchAd: () -> Void
    /// Opens the paywall over the scanner (offer and limit states).
    let onGoPremium: () -> Void

    var body: some View {
        switch phase {
        case .notFound(let code):
            VStack(spacing: 10) {
                primaryButton("Create manually") { onCreateManually(code) }
                secondaryButton("Scan again", action: onScanAgain)
            }
        case .denied:
            VStack(spacing: 10) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link(destination: url) { primaryLabel("Open Settings") }
                }
                secondaryButton("Add manually instead") { onCreateManually("") }
            }
        case .offline(let code), .serverError(let code):
            VStack(spacing: 10) {
                primaryButton("Retry") { onRetry(code) }
                secondaryButton("Scan again", action: onScanAgain)
            }
        case .rewardOffer:
            VStack(spacing: 10) {
                primaryButton("Watch ad", systemImage: "play.fill", action: onWatchAd)
                secondaryButton("Go Premium", action: onGoPremium)
            }
        case .limitReached:
            VStack(spacing: 10) {
                primaryButton("Unlock unlimited scans", action: onGoPremium)
                secondaryButton("Add manually instead") { onCreateManually("") }
            }
        case .scanning, .searching, .found, .requestingPermission, .handedOff:
            EmptyView()
        }
    }

    // MARK: - Buttons

    private func primaryButton(
        _ title: LocalizedStringKey, systemImage: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) { primaryLabel(title, systemImage: systemImage) }
    }

    private func primaryLabel(
        _ title: LocalizedStringKey, systemImage: String? = nil
    ) -> some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
            }
            Text(title)
                .font(.body.bold())
                .ctaFit()
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.accentStrong)
        )
        .shadow(color: Theme.accentStrong.opacity(0.5), radius: 10, x: 0, y: 8)
    }

    private func secondaryButton(
        _ title: LocalizedStringKey, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .ctaFit()
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.1))
                )
        }
    }
}

#Preview {
    ZStack {
        Theme.scanBackground.ignoresSafeArea()
        VStack(spacing: 40) {
            ScanActionBar(
                phase: .notFound("4820000123456"),
                onCreateManually: { _ in },
                onScanAgain: {},
                onRetry: { _ in },
                onWatchAd: {},
                onGoPremium: {}
            )
            ScanActionBar(
                phase: .rewardOffer,
                onCreateManually: { _ in },
                onScanAgain: {},
                onRetry: { _ in },
                onWatchAd: {},
                onGoPremium: {}
            )
        }
        .padding(.horizontal, 20)
    }
}
