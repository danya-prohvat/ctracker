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
}
