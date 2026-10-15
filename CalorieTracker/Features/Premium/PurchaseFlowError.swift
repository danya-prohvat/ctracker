import SwiftUI
#if canImport(RevenueCat)
import RevenueCat
#endif

/// Which paywall action raised an error — decides the alert title ("Purchase
/// failed" vs "Restore failed"), nothing else.
enum PurchaseFlowPhase {
    case purchase
    case restore
}

/// User-facing classification of a billing error. The store SDK reports its
/// errors with English-only descriptions, so the recognisable cases are
/// re-worded with the app's own localized strings; anything unrecognised keeps
/// its `localizedDescription` (the service's own `LocalizedError`s are already
/// in the app language and pass through untouched).
enum PurchaseFlowError: Error {
    /// Restore succeeded but the Apple Account has nothing to restore.
    case nothingToRestore
    /// Ask to Buy / deferred payment — not a failure.
    case pending
    case offline
    case notAllowed
    case storeUnavailable
    case other(String)

    init(_ error: Error) {
        if let flowError = error as? PurchaseFlowError {
            self = flowError
            return
        }
        #if canImport(RevenueCat)
        if let code = Self.revenueCatCode(of: error) {
            switch code {
            case .paymentPendingError:
                self = .pending
            case .networkError, .offlineConnectionError:
                self = .offline
            case .purchaseNotAllowedError:
                self = .notAllowed
            case .storeProblemError, .productNotAvailableForPurchaseError:
                self = .storeUnavailable
            default:
                self = .other(error.localizedDescription)
            }
            return
        }
        #endif
        if error is URLError {
            self = .offline
        } else {
            self = .other(error.localizedDescription)
        }
    }

    /// True when the user backed out of the store sheet — the paywall stays
    /// open and shows nothing.
    static func isUserCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        #if canImport(RevenueCat)
        if revenueCatCode(of: error) == .purchaseCancelledError { return true }
        #endif
        return false
    }

    #if canImport(RevenueCat)
    /// The SDK throws `ErrorCode` bridged into `NSError`; try the direct cast
    /// first and fall back to the domain + code pair.
    private static func revenueCatCode(of error: Error) -> ErrorCode? {
        if let code = error as? ErrorCode { return code }
        let nsError = error as NSError
        guard nsError.domain == ErrorCode.errorDomain else { return nil }
        return ErrorCode(rawValue: nsError.code)
    }
    #endif
}

/// What the paywall alert shows: a short title and a one-line message.
/// Informational outcomes (pending, nothing to restore) are not "failures" and
/// get their own titles; real errors are titled by phase.
struct PurchaseFlowAlert: Identifiable {
    let id = UUID()
    let title: LocalizedStringKey
    let message: Text

    init(_ error: PurchaseFlowError, phase: PurchaseFlowPhase) {
        switch error {
        case .nothingToRestore:
            title = "Nothing to restore"
            message = Text("No previous purchase was found for this Apple Account.")
        case .pending:
            title = "Purchase pending"
            message = Text("Your purchase is waiting for approval. Premium unlocks once it is approved.")
        case .offline:
            title = Self.failureTitle(phase)
            message = Text("You appear to be offline. Check your connection and try again.")
        case .notAllowed:
            title = Self.failureTitle(phase)
            message = Text("In-app purchases are not allowed on this device.")
        case .storeUnavailable:
            title = Self.failureTitle(phase)
            message = Text("The App Store is unavailable right now. Please try again later.")
        case .other(let description):
            title = Self.failureTitle(phase)
            message = Text(verbatim: description)
        }
    }

    init(_ error: Error, phase: PurchaseFlowPhase) {
        self.init(PurchaseFlowError(error), phase: phase)
    }

    private static func failureTitle(_ phase: PurchaseFlowPhase) -> LocalizedStringKey {
        switch phase {
        case .purchase: return "Purchase failed"
        case .restore: return "Restore failed"
        }
    }
}

extension View {
    /// Single-OK alert driven by a `PurchaseFlowAlert?` binding (non-nil =
    /// presented). Dismissing clears the binding; the paywall stays open.
    func purchaseFlowAlert(_ alert: Binding<PurchaseFlowAlert?>) -> some View {
        self.alert(
            alert.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { alert.wrappedValue != nil },
                set: { if !$0 { alert.wrappedValue = nil } }
            ),
            presenting: alert.wrappedValue
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { item in
            item.message
        }
    }
}
