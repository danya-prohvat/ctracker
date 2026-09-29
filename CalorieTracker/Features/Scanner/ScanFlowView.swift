import SwiftUI
import SwiftData
import AVFoundation

/// Full-screen barcode scan flow (spec §7), dark-themed per the prototype.
///
/// State machine: scanning → (own DB hit → `onLocalProduct`) → searching →
/// found (`onPrefill`) / not found (`onCreateManually`) / offline (retry),
/// plus camera-permission-denied, the opt-in "Watch ad" offer that holds a
/// found product back, and the daily free-scan limit the flow can open on
/// (user decision 2026-09-28). The caller owns navigation: this view only
/// reports outcomes through its callbacks and dismisses itself.
struct ScanFlowView: View {
    // Internal (not private): ScanFlowLookup.swift extends this type.
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss

    let onLocalProduct: (Product) -> Void
    let onPrefill: (ScanPrefill) -> Void
    let onCreateManually: (String) -> Void
    /// True when the free scans are used up: the flow opens on `.limitReached`
    /// instead of asking for the camera.
    let startsLocked: Bool

    init(
        startsLocked: Bool = false,
        onLocalProduct: @escaping (Product) -> Void,
        onPrefill: @escaping (ScanPrefill) -> Void,
        onCreateManually: @escaping (String) -> Void
    ) {
        self.startsLocked = startsLocked
        self.onLocalProduct = onLocalProduct
        self.onPrefill = onPrefill
        self.onCreateManually = onCreateManually
    }

    @State var phase: ScanFlowPhase = .requestingPermission
    /// Bumped to recreate the scanner view — it reports each code only once.
    @State private var scanToken = 0
    @State private var didRequestPermission = false
    /// Manual barcode entry (user decision 2026-09-28): the sheet hands its
    /// code over, the lookup runs after the sheet is gone (`finishManualEntry`).
    @State private var showManualEntry = false
    @State private var pendingManualCode: String?
    /// Last camera-reported code, for the same-code debounce.
    @State private var lastScan: (code: String, at: Date)?
    /// In-flight OFF lookup — cancelled when the scanner is dismissed, so a
    /// late response can't fire ads/callbacks over an unrelated screen.
    @State var lookupTask: Task<Void, Never>?
    /// The found product held back behind the "Watch ad" offer.
    @State var pendingPrefill: ScanPrefill?
    /// Paywall opened from the offer / limit screens; a fresh premium on
    /// return unlocks the flow (`paywallClosed`).
    @State var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            ScanFlowHeader(onBack: { dismiss() })
            ScanCenterContent(
                phase: phase,
                scanToken: scanToken,
                onScannedCode: handleScannedCode,
                onEnterManually: { showManualEntry = true }
            )
            ScanBottomBar(
                phase: phase,
                onCreateManually: onCreateManually,
                onScanAgain: restartScanning,
                onRetry: lookup,
                onWatchAd: watchAd,
                onGoPremium: { showPaywall = true }
            )
        }
        .background(Theme.scanBackground.ignoresSafeArea())
        // Viewfinder, status panel and action bar fade between phases.
        .animation(.easeInOut(duration: 0.2), value: phase)
        .adaptiveSheet(isPresented: $showManualEntry, onDismiss: finishManualEntry) {
            ScanManualEntrySheet { code in pendingManualCode = code }
        }
        .adaptiveSheet(isPresented: $showPaywall, onDismiss: paywallClosed) {
            PaywallView()
        }
        .task {
            if startsLocked {
                phase = .limitReached
                return
            }
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

    // MARK: - Logic (lookup, ad offer and reveal live in ScanFlowLookup.swift)

    private func ensurePermission() async {
        guard !didRequestPermission else { return }
        didRequestPermission = true
        #if targetEnvironment(simulator)
        // No camera hardware — go straight to scanning; the manual-entry
        // link covers the missing camera.
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
    /// of looping the lookup. Manual entry feeds `handleCode` directly, silent.
    private func handleScannedCode(_ rawCode: String) {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        // The camera keeps running under the manual-entry sheet — ignore it.
        guard !code.isEmpty, !showManualEntry else { return }
        if let last = lastScan, last.code == code,
           Date().timeIntervalSince(last.at) < ScanFeedback.debounceInterval {
            scanToken += 1
            return
        }
        lastScan = (code, Date())
        ScanFeedback.success()
        handleCode(code)
    }

    private func restartScanning() {
        scanToken += 1
        phase = .scanning
    }

    /// Runs after the manual-entry sheet is fully gone, so a local hand-off
    /// or the ad offer never races the sheet's dismissal. Closed without a
    /// code: recreate the scanner — it reports each code once, and a code
    /// seen while the sheet was up was ignored.
    private func finishManualEntry() {
        if let code = pendingManualCode {
            pendingManualCode = nil
            handleCode(code)
        } else if case .scanning = phase {
            scanToken += 1
        }
    }

    /// Back from the paywall: a fresh premium unlocks whatever it was opened
    /// from — the held-back result is revealed, or the locked flow starts
    /// scanning for real. Still free: stay where we were.
    private func paywallClosed() {
        guard PremiumGate.isPremium(settings: UserSettings.current(in: context)) else { return }
        switch phase {
        case .rewardOffer: revealPending()
        case .limitReached: Task { await ensurePermission() }
        default: break
        }
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

#Preview("Limit reached") {
    ScanFlowView(
        startsLocked: true,
        onLocalProduct: { _ in },
        onPrefill: { _ in },
        onCreateManually: { _ in }
    )
    .modelContainer(PreviewData.container)
}
