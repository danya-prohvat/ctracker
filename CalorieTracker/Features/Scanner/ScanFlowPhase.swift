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
    /// A local product was handed to the caller; waiting for it to navigate.
    case handedOff
}
