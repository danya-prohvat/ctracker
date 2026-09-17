import SwiftUI
import SwiftData

/// The "Logged" section of `DayView` (header line, empty card or the diary
/// list) plus entry deletion — an extension in its own file to keep DayView
/// under the size cap. DayView's shared state is therefore internal, not
/// private, on purpose (same pattern as the onboarding steps).
extension DayView {
    var loggedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Logged")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("^[\(shownEntries.count) item](inflect: true) · \(Format.kcal(totalCalories)) kcal")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)

            if shownEntries.isEmpty {
                DayEmptyStateCard(
                    isToday: true,
                    dateLabel: dayLabel,
                    onAdd: isPresented ? { showingAdd = true } : nil
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                DiaryListCard(
                    entries: shownEntries,
                    unitSystem: settings?.unitSystem ?? .metric,
                    showsAddFooter: isPresented,
                    onTap: { editing = EditingEntry(entry: $0) },
                    onDelete: { pendingDelete = $0 },
                    onAdd: { showingAdd = true }
                )
                if isPresented {
                    Text("Swipe a row to delete · tap to edit quantity.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                }
            }
        }
    }

    func delete(_ entry: DiaryEntry) {
        context.delete(entry)
        try? context.save()
    }
}
