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
    @State private var showScheduled = false
    @State private var reviewNote: LocalizedStringKey?
    @State private var adsGraceNote: LocalizedStringKey?

    var body: some View {
        VStack(spacing: 0) {
            premiumRow
            SettingsRowDivider()
            actionRow("Seed sample data", note: seedNote) {
                let count = Seeder.seedSampleData(context)
                seedNote = count > 0 ? "Seeded \(count) entries" : "Store not empty"
            }
            SettingsRowDivider()
            actionRow("Reset free scans", note: "Used: \(settings.scanCount)") {
                settings.scanCount = 0
                try? context.save()
            }
            SettingsRowDivider()
            actionRow(
                "Ads: skip ad-free day",
                note: adsGraceNote ?? (AdsGracePeriod.isActive ? "Active" : "Over")
            ) {
                AdsGracePeriod.debugSkip()
                adsGraceNote = "Over"
            }
            SettingsRowDivider()
            actionRow("Ads: restart ad-free day", note: nil) {
                AdsGracePeriod.debugReset()
                adsGraceNote = "Active"
            }
            SettingsRowDivider()
            actionRow("Reset onboarding", note: onboardingNote) {
                settings.onboardingCompleted = false
                settings.onboardingStep = 0
                try? context.save()
                onboardingNote = "Restart the app"
            }
            SettingsRowDivider()
            actionRow("Scheduled notifications", note: nil) {
                showScheduled = true
            }
            SettingsRowDivider()
            actionRow("Test re-engagement (minutes)", note: nil) {
                ReengagementNotificationService
                    .scheduleTestSeriesMinutes(languageCode: settings.languageCode)
            }
            SettingsRowDivider()
            actionRow(
                "Review: advance day",
                note: reviewNote ?? "Day \(ReviewPromptService.debugDayNumber)"
            ) {
                ReviewPromptService.debugAdvanceDay()
                reviewNote = "Day \(ReviewPromptService.debugDayNumber)"
            }
            SettingsRowDivider()
            actionRow("Review: reset triggers", note: nil) {
                ReviewPromptService.debugReset()
                reviewNote = "Day \(ReviewPromptService.debugDayNumber)"
            }
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
        .adaptiveSheet(isPresented: $showScheduled) {
            PendingNotificationsSheet()
        }
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
                // Same path as a real entitlement change, so toggling the
                // override off also trims tracked nutrients to the free set.
                PremiumGate.applyEntitlement(newValue, settings: settings)
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
