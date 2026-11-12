import SwiftUI
import SwiftData

/// Pushed from Settings → General → iCloud sync (user decision 2026-11-12:
/// no switches on the Settings root). The switch plus what it does; the
/// store itself is rebuilt on the next launch (see `CloudSync`), so the
/// restart footnote shows until the states agree again.
struct CloudSyncSettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let settings: UserSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                toggleCard
                    .padding(.top, 8)
                Text("Keeps your products, diary and goals in sync across your devices.")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 6)
                if CloudSync.needsRestart(settings: settings) {
                    Text("Applies after restarting the app")
                        .font(.caption)
                        .foregroundStyle(Theme.warning)
                        .padding(.horizontal, 6)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .contentColumn()
        }
        .contentMargins(.bottom, 110, for: .scrollContent)
        .background(AppBackground())
        .hidesFloatingTabBar()
        .detailNavBar(title: Text("iCloud sync"), onBack: { dismiss() })
    }

    // Same shape as every other switch row: explicit label + hidden-label
    // Toggle (the app switch style draws only the switch).
    private var toggleCard: some View {
        HStack(spacing: 12) {
            SettingsRowIcon(systemName: "icloud", tint: Theme.tileTeal)
            Text("iCloud sync")
                .font(.callout)
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
            Toggle(isOn: iCloudBinding) { Text("iCloud sync") }
                .labelsHidden()
                .tint(Theme.accent)
        }
        .settingsIconRowPadding()
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    private var iCloudBinding: Binding<Bool> {
        Binding(
            get: { settings.iCloudSyncEnabled },
            set: { newValue in
                settings.iCloudSyncEnabled = newValue
                try? context.save()
                // The store is rebuilt on the next launch (see CloudSync);
                // the footnote shows until then.
                CloudSync.refresh(in: context)
            }
        )
    }
}

#Preview {
    NavigationStack {
        CloudSyncSettingsView(settings: UserSettings())
    }
    .modelContainer(PreviewData.container)
}
