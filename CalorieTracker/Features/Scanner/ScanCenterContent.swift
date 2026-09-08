import SwiftUI

/// Center block of the scan flow: the viewfinder (in the phases where the
/// camera is live or its last frame is relevant) above the per-phase status
/// panel. Split out of `ScanFlowView` to keep it under the file-size limit.
struct ScanCenterContent: View {
    let phase: ScanFlowPhase
    /// Bumped by the flow to recreate the scanner — it reports each code once.
    let scanToken: Int
    let onScannedCode: (String) -> Void

    private var showsViewfinder: Bool {
        switch phase {
        case .scanning, .searching: return true
        default: return false
        }
    }

    var body: some View {
        VStack(spacing: 26) {
            if showsViewfinder {
                ScanViewfinder {
                    #if DEBUG
                    if let photo = ScanMockPhoto.image {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                    } else {
                        liveCamera
                    }
                    #else
                    liveCamera
                    #endif
                }
            }
            ScanStatusPanel(phase: phase)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var liveCamera: some View {
        if case .scanning = phase {
            BarcodeScannerScreen(onCode: onScannedCode)
                .id(scanToken)
        }
    }
}
