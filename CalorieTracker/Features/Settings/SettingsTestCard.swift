#if DEBUG
import SwiftUI
import SwiftData

/// Debug-only "Test" card on the Settings root: runtime switches that mirror
/// the DEBUG launch arguments (premium override, scan counter, sample data,
/// onboarding reset). The whole file is compiled out of release builds.
struct SettingsTestCard: View {
    @Environment(\.modelContext) private var context

    let settings: UserSettings

    @State private var seedNote: LocalizedStringKey?
    @State private var onboardingNote: LocalizedStringKey?

    var body: some View {
        VStack(spacing: 0) {
            premiumRow
            SettingsRowDivider()
            actionRow("Seed sample data", note: seedNote) {
                seedNote = Seeder.seedSampleData(context) ? "Done" : "Store not empty"
            }
            SettingsRowDivider()
            actionRow("Reset free scans", note: "Used: \(settings.scanCount)") {
                settings.scanCount = 0
                try? context.save()
            }
            SettingsRowDivider()
            actionRow("Reset onboarding", note: onboardingNote) {
                settings.onboardingCompleted = false
                settings.onboardingStep = 0
                try? context.save()
                onboardingNote = "Restart the app"
            }
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    // MARK: - Rows

    private var premiumRow: some View {
        HStack(spacing: 12) {
            Text("Premium override")
                .font(.callout)
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
            Toggle(isOn: premiumBinding) { Text("Premium override") }
                .labelsHidden()
                .tint(Theme.accent)
        }
        .settingsRowPadding()
    }

    private func actionRow(
        _ title: LocalizedStringKey, note: LocalizedStringKey?, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.callout)
                    .foregroundStyle(Theme.accentLabel)
                Spacer(minLength: 12)
                if let note {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .settingsRowPadding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var premiumBinding: Binding<Bool> {
        Binding(
            get: { settings.isPremium },
            set: { newValue in
                settings.isPremium = newValue
                try? context.save()
            }
        )
    }
}

#Preview {
    ZStack {
        AppBackground()
        SettingsTestCardPreviewHost()
    }
    .modelContainer(PreviewData.container)
}

private struct SettingsTestCardPreviewHost: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        SettingsTestCard(settings: UserSettings.current(in: context))
            .padding(20)
    }
}
#endif
