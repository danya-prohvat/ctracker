import SwiftUI
import SwiftData

/// Pushed from Settings → Reminders: edit the daily meal-reminder times.
/// Scheduling behavior is unchanged; only the container is restyled to the
/// prototype's pushed-subscreen template.
struct SettingsRemindersView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let settings: UserSettings

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    card
                    Text("We'll remind you to log your meals at these times.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .background(AppBackground())
        .toolbar(.hidden, for: .navigationBar)
        .hidesFloatingTabBar()
    }

    private var header: some View {
        ZStack {
            Text("Reminders")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundStyle(Theme.accentLabel)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
    }

    private var card: some View {
        VStack(spacing: 0) {
            ForEach(settings.reminderTimesMinutes.indices, id: \.self) { index in
                reminderRow(index)
                SettingsRowDivider()
            }
            addRow
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    private func reminderRow(_ index: Int) -> some View {
        HStack(spacing: 12) {
            Text("Reminder")
                .font(.system(size: 16))
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
            DatePicker(
                "Reminder",
                selection: timeBinding(index),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            Button {
                remove(index)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.destructive)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var addRow: some View {
        Button {
            settings.reminderTimesMinutes.append(12 * 60)
            saveAndReschedule()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text("Add reminder")
                    .font(.system(size: 16))
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.accentLabel)
            .settingsRowPadding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func remove(_ index: Int) {
        guard settings.reminderTimesMinutes.indices.contains(index) else { return }
        settings.reminderTimesMinutes.remove(at: index)
        saveAndReschedule()
    }

    private func timeBinding(_ index: Int) -> Binding<Date> {
        Binding(
            get: {
                guard settings.reminderTimesMinutes.indices.contains(index) else { return Date() }
                let minutes = settings.reminderTimesMinutes[index]
                return Calendar.current.date(
                    bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()
                ) ?? Date()
            },
            set: { newDate in
                guard settings.reminderTimesMinutes.indices.contains(index) else { return }
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                settings.reminderTimesMinutes[index] =
                    (components.hour ?? 0) * 60 + (components.minute ?? 0)
                saveAndReschedule()
            }
        )
    }

    private func saveAndReschedule() {
        try? context.save()
        SettingsReminderScheduler.reschedule(minutesList: settings.reminderTimesMinutes)
    }
}

#Preview {
    NavigationStack {
        SettingsRemindersView(
            settings: UserSettings.current(in: PreviewData.container.mainContext)
        )
    }
    .modelContainer(PreviewData.container)
}
