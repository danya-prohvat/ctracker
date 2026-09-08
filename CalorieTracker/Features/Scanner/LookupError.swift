import Foundation

/// Typed failure of an online barcode lookup, so the UI can tell "you're
/// offline" from "the server is having trouble" (rate limit, 5xx) — both are
/// retryable, but the copy differs. Cancellation is deliberately NOT mapped:
/// `URLError(.cancelled)` propagates as-is and is swallowed by the caller's
/// `Task.isCancelled` guard (see `ScanFlowView.lookupTask`).
enum LookupError: Error {
    /// No network path to the server (airplane mode, connection lost, timeout).
    case offline
    /// The server answered, but not usably (429/5xx or a non-HTTP response).
    case serverError
}
