import SwiftUI
import SwiftData
import AVFoundation

/// Full-screen barcode scan flow (spec §7), dark-themed per the prototype.
///
/// State machine: scanning → (own DB hit → `onLocalProduct`) → searching →
/// found (`onPrefill`) / not found (`onCreateManually`) / offline (retry),
/// plus a camera-permission-denied state. The caller owns navigation: this
/// view only reports outcomes through its callbacks and dismisses itself.
struct ScanFlowView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let onLocalProduct: (Product) -> Void
    let onPrefill: (ScanPrefill) -> Void
    let onCreateManually: (String) -> Void

    init(
        onLocalProduct: @escaping (Product) -> Void,
        onPrefill: @escaping (ScanPrefill) -> Void,
        onCreateManually: @escaping (String) -> Void
    ) {
        self.onLocalProduct = onLocalProduct
        self.onPrefill = onPrefill
        self.onCreateManually = onCreateManually
    }

    @State private var phase: ScanFlowPhase = .requestingPermission
    /// Bumped to recreate the scanner view — it reports each code only once.
    @State private var scanToken = 0
    @State private var manualCode = ""
    @State private var didRequestPermission = false
    /// Last camera-reported code, for the same-code debounce.
    @State private var lastScan: (code: String, at: Date)?

    private var showsViewfinder: Bool {
        switch phase {
        case .scanning, .searching: return true
        default: return false
        }
    }

    private var showsAttribution: Bool {
        switch phase {
        case .searching, .found, .notFound: return true
        default: return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScanFlowHeader(onBack: { dismiss() })
            centerContent
            bottomBar
        }
        .background(Theme.scanBackground.ignoresSafeArea())
        // Viewfinder, status panel and action bar fade between phases.
        .animation(.easeInOut(duration: 0.2), value: phase)
        .task { await ensurePermission() }
    }

    // MARK: - Layout

    private var centerContent: some View {
        VStack(spacing: 26) {
            if showsViewfinder {
                ScanViewfinder {
                    if case .scanning = phase {
                        BarcodeScannerScreen(onCode: handleScannedCode)
                            .id(scanToken)
                    }
                }
            }
            ScanStatusPanel(phase: phase)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            ScanActionBar(
                phase: phase,
                manualCode: $manualCode,
                onManualLookup: handleCode,
                onCreateManually: onCreateManually,
                onScanAgain: restartScanning,
                onRetry: lookup
            )
            if showsAttribution {
                // ODbL attribution — required whenever OFF data is shown or fetched.
                Text("Data from Open Food Facts")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // MARK: - Logic

    private func ensurePermission() async {
        guard !didRequestPermission else { return }
        didRequestPermission = true
        #if targetEnvironment(simulator)
        // No camera hardware — go straight to the scanning state where
        // the manual-lookup debug bar lives.
        phase = .scanning
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            phase = .scanning
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            phase = granted ? .scanning : .denied
        default: // .denied, .restricted
            phase = .denied
        }
        #endif
    }

    /// Camera path only: haptic + sound on recognition, and a re-report of the
    /// same code within the debounce window silently resumes scanning instead
    /// of looping the lookup. Manual (debug) lookup calls `handleCode` directly.
    private func handleScannedCode(_ rawCode: String) {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        if let last = lastScan, last.code == code,
           Date().timeIntervalSince(last.at) < ScanFeedback.debounceInterval {
            scanToken += 1
            return
        }
        lastScan = (code, Date())
        ScanFeedback.success()
        handleCode(code)
    }

    private func handleCode(_ rawCode: String) {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }

        // Own database first — no network needed for products we already know.
        if let product = localProduct(for: code) {
            phase = .handedOff
            onLocalProduct(product)
            return
        }
        lookup(code)
    }

    private func localProduct(for code: String) -> Product? {
        ProductStore.existing(barcode: code, in: context)
    }

    private func lookup(_ code: String) {
        phase = .searching(code)
        Task {
            do {
                let result = try await BarcodeLookupService.lookup(barcode: code)
                switch result {
                case .found(let prefill):
                    phase = .found
                    onPrefill(prefill)
                case .notFound:
                    phase = .notFound(code)
                }
            } catch {
                phase = .offline(code)
            }
        }
    }

    private func restartScanning() {
        manualCode = ""
        scanToken += 1
        phase = .scanning
    }
}

#Preview {
    ScanFlowView(
        onLocalProduct: { _ in },
        onPrefill: { _ in },
        onCreateManually: { _ in }
    )
    .modelContainer(PreviewData.container)
}
