import SwiftUI
import SwiftData

/// Scene-lifecycle work of the root view, split out to keep RootView short.
extension RootView {
    func handleScenePhase(_ phase: ScenePhase) {
        if phase == .active {
            // ATT on first launch (user decision 2026-07-13). The system alert
            // only appears while active, hence scenePhase and not .task.
            // Notifications follow right after ATT (user decision
            // 2026-09-27): reminders are on by default, so the permission
            // is asked here once, not from the Settings toggle.
            Task {
                await TrackingConsent.requestIfNeeded()
                await NotificationStartupPrompt.requestIfNeeded(in: context)
            }
        }
        // Replan the smart meal reminders whenever the app gains or loses
        // focus — logging only happens in-app, so this keeps the planned
        // 14:00/20:00 notifications in sync with the diary.
        if phase == .active || phase == .background {
            MealReminderScheduler.reschedule(in: context)
            // Push today's totals to the home-screen widget — covers edits
            // and deletes too, since those only happen in-app.
            WidgetBridge.refresh(in: context)
        }
        // Restart the re-engagement countdown on every activation — a
        // series notification only fires if the app stays unopened.
        if phase == .active {
            ReengagementNotificationService.reschedule(in: context)
            Task {
                let settings = UserSettings.current(in: context)
                // Re-mirror the paid entitlement — purchase() and restore()
                // are otherwise the only reads, so without this an expired
                // subscription would keep premium forever.
                if !Self.skipsEntitlementSync {
                    await PurchaseServices.make(settings: settings).syncEntitlement()
                }
                try? context.save()
                // Warm the paywall price cache so plan rows render instantly
                // whenever the paywall opens (user decision 2026-08-03).
                await PaywallQuotesCache.prefetch(settings: settings)
            }
            // App-open + green-zone review triggers (user decision 2026-07-21).
            ReviewPromptService.checkOnActivation(in: context)
            // Keep the CloudKit-store mirror in sync with the toggle —
            // applies on the next start.
            CloudSync.refresh(in: context)
            // A cloud merge can bring in barcode twins from other devices.
            if CloudSync.activeThisLaunch {
                ProductStore.dedupeMerged(in: context)
            }
        }
    }

    /// Mirrors the backend's customer-info stream into `UserSettings` for as
    /// long as the root view lives (`.task`); the service saves the context
    /// itself after each update. Same screenshot exemption as the activation
    /// sync — a live verdict would revoke the seeded premium mid-frame.
    func observeEntitlement() async {
        guard !Self.skipsEntitlementSync else { return }
        await PurchaseServices.make(settings: UserSettings.current(in: context)).observeEntitlement()
    }

    /// Screenshot launches (`-seedScreenshotDay 1`) and the Settings → Test
    /// premium override (`debugPremiumOverride`, written by the toggle) pin
    /// the local flag, so no backend verdict may touch it.
    private static var skipsEntitlementSync: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "seedScreenshotDay")
            || UserDefaults.standard.bool(forKey: "debugPremiumOverride")
        #else
        false
        #endif
    }
}
