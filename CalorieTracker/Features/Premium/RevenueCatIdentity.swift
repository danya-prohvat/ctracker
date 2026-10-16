import Foundation

#if canImport(RevenueCat)
import CloudKit
import RevenueCat

/// Stable RevenueCat identity across devices and reinstalls (fixed 2026-10-15).
///
/// Without it every install is a fresh anonymous RevenueCat user: a second
/// iPhone (or a reinstall) asked the backend, got "not entitled" and revoked
/// the premium that CloudKit had just synced in. The CloudKit user record ID
/// is the same on every device signed into the same iCloud account and needs
/// no sign-in of our own, so it serves as the app user ID: `logIn` aliases
/// the anonymous user (and its purchases) into that identity.
///
/// Any failure — no iCloud account, offline, SDK error — keeps the current
/// (anonymous) user; `logOut` is never called. One attempt per process: a
/// device without an iCloud account would otherwise ask CloudKit on every
/// activation, and the next launch retries anyway.
@MainActor
enum RevenueCatIdentity {
    private static var attempted = false
    private static var inFlight: Task<Void, Never>?

    /// Logs the SDK in as the iCloud user when possible. Safe to call from
    /// several places at once — concurrent callers await the same attempt.
    static func identifyIfNeeded() async {
        guard !attempted, Purchases.isConfigured else { return }
        if let running = inFlight {
            await running.value
            return
        }
        let attempt = Task { await identify() }
        inFlight = attempt
        await attempt.value
        inFlight = nil
        attempted = true
    }

    private static func identify() async {
        let container = CKContainer(identifier: CloudSync.containerID)
        guard let recordID = try? await container.userRecordID() else { return }
        let userID = recordID.recordName
        if Purchases.shared.appUserID != userID {
            _ = try? await Purchases.shared.logIn(userID)
        }
    }
}
#endif
