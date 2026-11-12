import SwiftUI

/// "Appearance" row of the General card: System / Light / Dark as a compact
/// menu picker (short one-word options — long sentences would go inline, see
/// CLAUDE.md). Writes `AppAppearance` to UserDefaults; `RootView` reads the
/// same key, so the scheme switches the moment an option is picked.
struct SettingsAppearanceRow: View {
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .system

    var body: some View {
        HStack(spacing: 12) {
            SettingsRowIcon(systemName: "circle.lefthalf.filled", tint: Theme.tileGray)
            Text("Appearance")
                .font(.callout)
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 12)
            Picker(selection: $appearance) {
                ForEach(AppAppearance.allCases) { option in
                    Text(option.label).tag(option)
                }
            } label: {
                Text("Appearance")
            }
            .pickerStyle(.menu)
            .labelsHidden()
            // Value text reads like the Language row's value, not like a link.
            .tint(Theme.textTertiary)
        }
        .settingsIconRowPadding()
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 0) {
            SettingsAppearanceRow()
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
        .padding(20)
    }
}

#Preview("Dark") {
    ZStack {
        AppBackground()
        VStack(spacing: 0) {
            SettingsAppearanceRow()
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
