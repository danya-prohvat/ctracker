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
            }
            // Restart the re-engagement countdown on every activation — a
            // series notification only fires if the app stays unopened.
            if phase == .active {
                ReengagementNotificationService.reschedule(in: context)
                // Keep the CloudKit-store mirror honest (premium may have
                // lapsed since last launch) — applies on the next start.
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
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
