import SwiftUI
import SwiftData

/// Settings tab root (spec §5, §9) restyled to the prototype: pastel
/// background, custom 30pt header, section captions and glass cards.
/// All behavior (gating, scheduling, delete flow) lives in the section cards.
struct SettingsHomeView: View {
    @Environment(\.modelContext) private var context

    @Query private var settingsList: [UserSettings]

    @State private var showPaywall = false
    @State private var debugShowGoals = false

    init() {}

    private var settings: UserSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            Group {
                if let settings {
                    content(settings)
                } else {
                    Color.clear
                }
            }
            .background(AppBackground())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $debugShowGoals) { GoalsView() }
        }
        .task {
            #if DEBUG
            // Launch with `-openGoals 1` to jump straight to Goals & nutrients.
            if UserDefaults.standard.bool(forKey: "openGoals") { debugShowGoals = true }
            #endif
        }
        .onAppear {
            if settingsList.isEmpty {
                _ = UserSettings.current(in: context)
                try? context.save()
            }
        }
    }

    // MARK: - Content

    private func content(_ settings: UserSettings) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 2)
                    .padding(.top, 6)
                    .padding(.bottom, 18)

                SettingsPremiumCard(settings: settings) { showPaywall = true }
                    .padding(.bottom, 12)

                caption("My goals")
                    .padding(.top, 2)
                SettingsGoalsCard(settings: settings)

                caption("Units")
                    .padding(.top, 14)
                SettingsUnitsPicker(settings: settings)

                caption("General")
                    .padding(.top, 14)
                SettingsGeneralCard(settings: settings) { showPaywall = true }

                caption("About")
                    .padding(.top, 14)
                SettingsAboutCard()
                Text("Data from Open Food Facts")
                    .font(.caption)
                    .foregroundStyle(Theme.textQuaternary)
                    .padding(.horizontal, 6)
                    .padding(.top, 8)

                SettingsDeleteCard(settings: settings)
                    .padding(.top, 14)

                #if DEBUG
                caption("Test")
                    .padding(.top, 14)
                SettingsTestCard(settings: settings)
                #endif

                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .contentMargins(.bottom, 110, for: .scrollContent)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Pieces

    private func caption(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.footnote)
            .textCase(.uppercase)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 6)
            .padding(.bottom, 8)
    }

    private var footer: some View {
        Text("Calorie Tracker · v\(appVersion)")
            .font(.caption)
            .foregroundStyle(Theme.textQuaternary)
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
    }

    private var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
            ?? "1.0"
    }
}

#Preview {
    SettingsHomeView()
        .modelContainer(PreviewData.container)
}
