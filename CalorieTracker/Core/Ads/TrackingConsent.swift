import AppTrackingTransparency

/// One-time App Tracking Transparency prompt on first launch (user decision
/// 2026-07-13). AdMob picks up the result automatically: granted → IDFA and
/// personalized ads, denied → contextual ads; ads keep serving either way.
@MainActor
enum TrackingConsent {
    /// Shows the system ATT alert if the user hasn't answered yet. Call only
    /// while the scene is active — iOS silently drops the alert otherwise.
    static func requestIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        // Give the first frame a beat: requesting in the same runloop tick the
        // scene becomes active can drop the alert on a cold launch.
        try? await Task.sleep(nanoseconds: 700_000_000)
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }
}
