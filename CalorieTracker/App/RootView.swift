import SwiftUI
import SwiftData

enum AppTab: String {
    case today, calendar, settings
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settingsList: [UserSettings]

    @State private var showOnboarding = false
    @State private var postOnboardingPaywall = false
    @State private var tabBarHidden = false
    @State private var selectedTab: AppTab = {
        #if DEBUG
        // Launch with `-initialTab calendar|settings` to open a specific tab.
        if let raw = UserDefaults.standard.string(forKey: "initialTab"),
           let tab = AppTab(rawValue: raw) {
            return tab
        }
        #endif
        return .today
    }()

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            Group {
                switch selectedTab {
                case .today: TodayView()
                case .calendar: CalendarTabView()
                case .settings: SettingsHomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Tab switch crossfades (branches use the default opacity transition).
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            .onPreferenceChange(TabBarHiddenPreferenceKey.self) { tabBarHidden = $0 }

            if !tabBarHidden {
                FloatingTabBar(selection: $selectedTab)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: tabBarHidden)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .tint(Theme.accent)
        // The palette is light-only for now; without this, system materials
        // and sheets would flip dark while cards/text stay light.
        .preferredColorScheme(.light)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // ATT on first launch (user decision 2026-07-13). The system alert
                // only appears while active, hence scenePhase and not .task.
                Task { await TrackingConsent.requestIfNeeded() }
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
                    #if DEBUG
                    // Screenshot launches pin the seeded premium override —
                    // a live RevenueCat answer would revoke it mid-frame.
                    let skipSync = UserDefaults.standard.bool(forKey: "seedScreenshotDay")
                    #else
                    let skipSync = false
                    #endif
                    if !skipSync {
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
        .onAppear {
            let settings = UserSettings.current(in: context)
            Seeder.seedIfRequested(context)
            #if DEBUG
            // Launch with `-seedScreenshotDay 1` to rebuild today as the fixed
            // App Store screenshot day (see ScreenshotSeeder).
            ScreenshotSeeder.seedIfRequested(context)
            // Launch with `-resetOnboarding 1` to re-run the first-launch flow,
            // or `-skipOnboarding 1` to force the main UI for verification.
            if UserDefaults.standard.bool(forKey: "resetOnboarding") {
                settings.onboardingCompleted = false
                settings.onboardingStep = 0
            }
            if UserDefaults.standard.bool(forKey: "skipOnboarding") {
                settings.onboardingCompleted = true
            }
            #endif
            showOnboarding = !settings.onboardingCompleted
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            if let settings = settingsList.first {
                OnboardingFlow(settings: settings) {
                    // Finished or skipped — same exit (user decision
                    // 2026-07-21): onboarding dismisses, Today shows for a
                    // beat, then the soft paywall slides up over it.
                    showOnboarding = false
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1))
                        postOnboardingPaywall = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $postOnboardingPaywall) { PaywallView() }
        // In-app language override takes effect immediately (locale + RTL);
        // AppleLanguages completes the switch on the next launch. Outermost
        // on purpose: presented covers inherit the environment only from
        // modifiers ABOVE their attachment point, so `.appLanguage` below the
        // `.fullScreenCover`s would leave onboarding/paywall un-overridden.
        .appLanguage(settingsList.first?.languageCode)
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
