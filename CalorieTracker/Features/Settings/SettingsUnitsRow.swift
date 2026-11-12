import SwiftUI
import SwiftData

/// "Units" row of the General card (spec §3): Metric / US as a compact menu
/// picker — one-word options, so menu (not inline) per CLAUDE.md. Replaces
/// the full-width segmented control of the old "Units" section (user
/// decision 2026-11-12); onboarding keeps its own segmented toggle.
struct SettingsUnitsRow: View {
    @Environment(\.modelContext) private var context

    let settings: UserSettings

    var body: some View {
        HStack(spacing: 12) {
            SettingsRowIcon(systemName: "scalemass", tint: Theme.tileBlue)
            Text("Units")
                .font(.callout)
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 12)
            Picker(selection: selection) {
                ForEach(UnitSystem.allCases) { system in
                    Text(system.shortLabel).tag(system)
                }
            } label: {
                Text("Units")
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(Theme.textTertiary)
        }
        .settingsIconRowPadding()
    }

    private var selection: Binding<UnitSystem> {
        Binding(
            get: { settings.unitSystem },
            set: { newValue in
                settings.unitSystem = newValue
                try? context.save()
            }
        )
    }
}
