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
    /// In-flight OFF lookup — cancelled when the scanner is dismissed, so a
    /// late response can't fire ads/callbacks over an unrelated screen.
    @State private var lookupTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            ScanFlowHeader(onBack: { dismiss() })
            ScanCenterContent(
                phase: phase,
                scanToken: scanToken,
                onScannedCode: handleScannedCode
            )
            ScanBottomBar(
                phase: phase,
                manualCode: $manualCode,
                onManualLookup: handleCode,
                onCreateManually: onCreateManually,
                onScanAgain: restartScanning,
                onRetry: lookup
            )
        }
        .background(Theme.scanBackground.ignoresSafeArea())
        // Viewfinder, status panel and action bar fade between phases.
        .animation(.easeInOut(duration: 0.2), value: phase)
        .task {
            await ensurePermission()
            await ScanRewardGate.preloadIfNeeded(context: context)
            #if DEBUG
            // Screenshot flow: `-scanAutoLookup <code>` fires the lookup as if
            // that barcode was just scanned (pairs with `-scanMockPhoto`).
            if let code = UserDefaults.standard.string(forKey: "scanAutoLookup"),
               !code.isEmpty {
                try? await Task.sleep(for: .milliseconds(800))
                handleCode(code)
            }
            #endif
        }
        .onDisappear { lookupTask?.cancel() }
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
        ProductStore.existing(scannedCode: code, in: context)
    }

    private func lookup(_ code: String) {
        phase = .searching(code)
        // In-app language for the prefilled product name — `Locale.current` is
        // frozen at launch and lags an in-session language switch.
        let languageCode = UserSettings.current(in: context).languageCode
        lookupTask?.cancel()
        lookupTask = Task {
            do {
                let result = try await BarcodeLookupService.lookup(barcode: code,
                                                                   languageCode: languageCode)
                guard !Task.isCancelled else { return }
                switch result {
                case .found(let prefill):
                    // Rewarded scan gate: the phase stays `.searching` while
                    // the ad is up — the outcome is only revealed after it
                    // closes, never announced beforehand.
                    ScanRewardGate.present(context: context) {
                        phase = .found
                        onPrefill(prefill)
                    }
                case .notFound:
                    phase = .notFound(code)
                }
            } catch {
                // Our own cancel also lands here (URLSession throws on it).
                guard !Task.isCancelled else { return }
                if case LookupError.serverError = error {
                    phase = .serverError(code)
                } else {
                    phase = .offline(code)
                }
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
