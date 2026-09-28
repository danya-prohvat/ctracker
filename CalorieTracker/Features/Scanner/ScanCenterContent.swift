import SwiftUI

/// Center block of the scan flow: the viewfinder (in the phases where the
/// camera is live or its last frame is relevant) above the per-phase status
/// panel. Split out of `ScanFlowView` to keep it under the file-size limit.
struct ScanCenterContent: View {
    let phase: ScanFlowPhase
    /// Bumped by the flow to recreate the scanner — it reports each code once.
    let scanToken: Int
    let onScannedCode: (String) -> Void
    let onEnterManually: () -> Void

    private var showsViewfinder: Bool {
        switch phase {
        case .scanning, .searching: return true
        default: return false
        }
    }

    /// Manual entry is offered wherever the camera is the only other way in:
    /// while scanning and when camera access is denied.
    private var showsManualEntryLink: Bool {
        #if DEBUG
        // Screenshot mode (`-scanMockPhoto`) keeps the frame clean.
        if ScanMockPhoto.isActive { return false }
        #endif
        switch phase {
        case .scanning, .denied: return true
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
            VStack(spacing: 6) {
                ScanStatusPanel(phase: phase)
                if showsManualEntryLink { manualEntryLink }
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Discreet text link (user decision 2026-09-28) — the field itself lives
    /// in `ScanManualEntrySheet` so the viewfinder never fights the keyboard.
    private var manualEntryLink: some View {
        Button(action: onEnterManually) {
            Text("Enter code manually")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.6))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var liveCamera: some View {
        if case .scanning = phase {
            BarcodeScannerScreen(onCode: onScannedCode)
                .id(scanToken)
        }
    }
}
