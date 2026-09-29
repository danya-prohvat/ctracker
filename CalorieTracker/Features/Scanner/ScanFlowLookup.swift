import SwiftUI

/// Code handling of the scan flow: own base → Open Food Facts lookup, the
/// opt-in rewarded-ad offer and the reveal. Split out of `ScanFlowView` to
/// keep it under the file-size limit (its state is internal on purpose).
extension ScanFlowView {
    func handleCode(_ rawCode: String) {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }

        // Own database first — no network needed for products we already know.
        if let product = ProductStore.existing(scannedCode: code, in: context) {
            phase = .handedOff
            onLocalProduct(product)
            return
        }
        lookup(code)
    }

    func lookup(_ code: String) {
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
                    offerOrReveal(prefill)
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

    /// Rewarded scan gate (user decision 2026-08-03, opt-in since 2026-09-28):
    /// when this scan costs an ad and one is loaded, the result waits behind
    /// the "Watch ad" offer — the outcome is announced, but not shown, until
    /// the user chooses. No ad ready = revealed for free, never blocked.
    private func offerOrReveal(_ prefill: ScanPrefill) {
        if ScanRewardGate.shouldOffer(context: context) {
            pendingPrefill = prefill
            phase = .rewardOffer
        } else {
            reveal(prefill)
        }
    }

    /// "Watch ad" tapped: the ad runs, and the reveal follows its dismissal
    /// whether or not the reward was earned (closing early still reveals).
    func watchAd() {
        ScanRewardGate.present(reveal: revealPending)
    }

    /// Hands the held-back result over (ad watched, or premium bought from
    /// the offer). Idempotent: the prefill is consumed on the first call.
    func revealPending() {
        guard let prefill = pendingPrefill else { return }
        pendingPrefill = nil
        reveal(prefill)
    }

    private func reveal(_ prefill: ScanPrefill) {
        phase = .found
        onPrefill(prefill)
    }
}
