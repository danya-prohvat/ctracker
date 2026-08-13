import SwiftUI

/// Bottom stack of the scan flow: the state-dependent action bar plus the
/// ODbL footer, shown in every phase where OFF data is fetched or displayed.
struct ScanBottomBar: View {
    let phase: ScanFlowPhase
    @Binding var manualCode: String
    let onManualLookup: (String) -> Void
    let onCreateManually: (String) -> Void
    let onScanAgain: () -> Void
    let onRetry: (String) -> Void

    private var showsAttribution: Bool {
        switch phase {
        case .searching, .found, .notFound: return true
        default: return false
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            ScanActionBar(
                phase: phase,
                manualCode: $manualCode,
                onManualLookup: onManualLookup,
                onCreateManually: onCreateManually,
                onScanAgain: onScanAgain,
                onRetry: onRetry
            )
            if showsAttribution {
                // ODbL attribution — required whenever OFF data is shown or fetched.
                Text("Data from Open Food Facts")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        // Cap sits inside the gutters: equals the widest iPhone layout, so
        // buttons keep their size there and stop stretching on iPad.
        .contentColumn(400)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
}
