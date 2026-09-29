import Foundation

/// Internal state machine for the scan flow (spec §7).
enum ScanFlowPhase: Equatable {
    case requestingPermission
    case scanning
    case searching(String)
    case found
    case notFound(String)
    case denied
    case offline(String)
    /// The lookup server responded with an error (rate limit / 5xx) while the
    /// user is online — retryable, but with different copy than `offline`.
    case serverError(String)
    /// A local product was handed to the caller; waiting for it to navigate.
    case handedOff
    /// The product was found, but this scan costs an ad: waiting for the user
    /// to tap "Watch ad" (or go Premium) before the result is revealed
    /// (user decision 2026-09-28, AdMob opt-in rule).
    case rewardOffer
    /// Free scans are used up for today — the flow opens straight into this
    /// (no camera) with the upgrade / manual-entry actions.
    case limitReached
}
