import SwiftUI
import SwiftData

enum AppTab: String {
    case today, calendar, settings
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [UserSettings]

    @State private var showOnboarding = false
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
                    .padding(.horizontal, 16)
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
                    showOnboarding = false
                }
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
