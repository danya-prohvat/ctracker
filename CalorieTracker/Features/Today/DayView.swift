import SwiftUI
import SwiftData

/// Day summary + diary list per the approved prototype. Drives both the Today
/// tab and the Calendar day-details screen. `isToday` follows the date; the
/// pushed (day-detail) chrome — back header, add footer, hint — follows
/// `\.isPresented` so a pushed "today" still gets a back button.
struct DayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented

    let dayKey: String
    let isToday: Bool

    @Query private var entries: [DiaryEntry]
    @Query private var settingsList: [UserSettings]

    @State private var showingAdd = false
    @State private var editing: EditingEntry?

    init(dayKey: String, isToday: Bool) {
        self.dayKey = dayKey
        self.isToday = isToday
        let key = dayKey
        _entries = Query(
            filter: #Predicate<DiaryEntry> { $0.dayKey == key },
            sort: \.loggedAt, order: .forward
        )
    }

    private var settings: UserSettings? { settingsList.first }
    private var totalCalories: Double { entries.reduce(0) { $0 + $1.calories } }
    private var dayDate: Date { DayKey.date(from: dayKey) ?? Date() }
    private var dayLabel: String { dayDate.formatted(.dateTime.month(.wide).day()) }
    /// Native large-title subtitle for the Today root, e.g. "Wednesday, 8 July".
    private var daySubtitle: String {
        dayDate.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    /// The Today root shows the floating "+"; the pushed day-detail doesn't.
    private var showsAddButton: Bool { isToday && !isPresented }
    /// Bottom scroll inset. With the FAB (62pt at bottom 88) present, keep the
    /// last card clear of it; otherwise just clear the floating tab bar.
    private var scrollBottomInset: CGFloat { showsAddButton ? 164 : 110 }

    /// Tab-root large title vs. pushed-detail inline bar. Both use the native
    /// nav bar so the title pins and the top blurs on scroll; the detail adds
    /// the green back button.
    private var navigationChrome: DayNavigationChrome {
        DayNavigationChrome(
            isPresented: isPresented,
            monthLabel: dayDate.formatted(.dateTime.month(.wide)),
            dayLabel: dayLabel,
            subtitle: daySubtitle,
            onBack: { dismiss() }
        )
    }

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 20)
                .padding(.top, 8)
        }
        .contentMargins(.bottom, scrollBottomInset, for: .scrollContent)
        .background(AppBackground())
        .modifier(navigationChrome)
        .hidesFloatingTabBar(isPresented)
        .overlay(alignment: .bottomTrailing) {
            // Day details keep an in-card add footer instead of the FAB, so
            // any day stays fully editable from the Calendar too (spec §5).
            if showsAddButton {
                FloatingAddButton { showingAdd = true }
                    .padding(.trailing, 26)
                    .padding(.bottom, 88)
            }
        }
        .fullScreenCover(isPresented: $showingAdd) {
            // Presented in its own NavigationStack rather than pushed into the
            // parent one. When DayView is itself a pushed calendar detail, a
            // second `navigationDestination` on the same stack jams navigation
            // (the add tap and the back button both freeze). A self-contained
            // cover keeps its inline nav bar (title + back + search) via
            // `.detailNavBar` and works from both Today and the calendar.
            NavigationStack {
                AddFoodSheet(dayKey: dayKey)
            }
        }
        .task {
            #if DEBUG
            // Launch with `-showAddSheet 1` to open the add flow immediately.
            if isToday && !isPresented && UserDefaults.standard.bool(forKey: "showAddSheet") {
                showingAdd = true
            }
            #endif
        }
        .sheet(item: $editing) { wrapper in
            QuantityEditSheet(entry: wrapper.entry)
        }
    }

    @ViewBuilder
    private var content: some View {
        if !isToday && entries.isEmpty {
            // Prototype: an empty past day shows only the gray empty card;
            // the add affordance stays for spec compliance.
            DayEmptyStateCard(isToday: false, dateLabel: dayLabel) { showingAdd = true }
                .padding(.top, 40)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                DaySummaryCard(entries: entries, settings: settings, isToday: isToday)
                loggedSection
                    .padding(.top, 26)
            }
        }
    }

    // MARK: - Logged

    private var loggedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Logged")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("^[\(entries.count) item](inflect: true) · \(Format.kcal(totalCalories)) kcal")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)

            if entries.isEmpty {
                DayEmptyStateCard(
                    isToday: true,
                    dateLabel: dayLabel,
                    onAdd: isPresented ? { showingAdd = true } : nil
                )
            } else {
                DiaryListCard(
                    entries: entries,
                    showsAddFooter: isPresented,
                    onTap: { editing = EditingEntry(entry: $0) },
                    onDelete: delete,
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

    private func delete(_ entry: DiaryEntry) {
        context.delete(entry)
        try? context.save()
    }
}

/// Applies the tab-root large title or the pushed-detail nav bar depending on
/// how `DayView` is shown. Date labels are verbatim `Text` (never localized as
/// keys); "Today" is the localized root title.
private struct DayNavigationChrome: ViewModifier {
    let isPresented: Bool
    let monthLabel: String
    let dayLabel: String
    let subtitle: String
    let onBack: () -> Void

    func body(content: Content) -> some View {
        if isPresented {
            content.detailNavBar(
                backLabel: Text(monthLabel),
                title: Text(dayLabel),
                onBack: onBack
            )
        } else {
            content.largeTitleScreen("Today", subtitle: subtitle)
        }
    }
}

/// Identifiable wrapper so `.sheet(item:)` can present a quantity editor for a
/// tapped entry without relying on model Identifiable semantics.
struct EditingEntry: Identifiable {
    let id = UUID()
    let entry: DiaryEntry
}

#Preview("Day detail") {
    NavigationStack {
        DayView(dayKey: DayKey.today, isToday: false)
    }
    .modelContainer(PreviewData.container)
}
