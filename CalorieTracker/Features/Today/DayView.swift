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
    // In-app language switch: eager `formatted(...)` strings must follow the
    // environment locale, not the launch-frozen `Locale.current`.
    @Environment(\.locale) private var locale

    let dayKey: String
    let isToday: Bool
    /// Reported to TodayView so a midnight day-key refresh is deferred while
    /// an add/edit flow is open (see TodayView). Nil on calendar day details.
    private let modalFlowActive: Binding<Bool>?

    @Query private var entries: [DiaryEntry]
    @Query private var settingsList: [UserSettings]

    @State private var showingAdd = false
    @State private var editing: EditingEntry?
    /// Entry awaiting delete confirmation (swipe or context menu). Deleting a
    /// logged entry is irreversible, so we always ask first.
    @State private var pendingDelete: DiaryEntry?

    init(dayKey: String, isToday: Bool, modalFlowActive: Binding<Bool>? = nil) {
        self.dayKey = dayKey
        self.isToday = isToday
        self.modalFlowActive = modalFlowActive
        let key = dayKey
        _entries = Query(
            filter: #Predicate<DiaryEntry> { $0.dayKey == key },
            sort: \.loggedAt, order: .forward
        )
    }

    private var settings: UserSettings? { settingsList.first }
    private var totalCalories: Double { entries.reduce(0) { $0 + $1.calories } }
    private var dayDate: Date { DayKey.date(from: dayKey) ?? Date() }
    private var dayLabel: String { dayDate.formatted(.dateTime.month(.wide).day().locale(locale)) }
    /// Native large-title subtitle for the Today root, e.g. "Wednesday, 8 July".
    private var daySubtitle: String {
        dayDate.formatted(.dateTime.weekday(.wide).month(.wide).day().locale(locale))
    }
    /// True while any add/edit modal of this screen is up.
    private var hasModalFlow: Bool { showingAdd || editing != nil }

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
            monthLabel: dayDate.formatted(.dateTime.month(.wide).locale(locale)),
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
                .contentColumn()
                // Diary rows slide in/out and the empty state swaps smoothly
                // when entries are logged or deleted.
                .animation(.snappy(duration: 0.35), value: entries.count)
        }
        .contentMargins(.bottom, scrollBottomInset, for: .scrollContent)
        .background(AppBackground())
        .modifier(navigationChrome)
        .hidesFloatingTabBar(isPresented)
        .overlay(alignment: .bottom) {
            // Day details keep an in-card add footer instead of the FAB, so
            // any day stays fully editable from the Calendar too (spec §5).
            // The 640 frame pins the FAB to the content column's trailing
            // edge on iPad instead of the screen corner.
            if showsAddButton {
                FloatingAddButton { showingAdd = true }
                    .padding(.trailing, 26)
                    .padding(.bottom, 88)
                    .frame(maxWidth: 640, alignment: .bottomTrailing)
            }
        }
        // Today keeps the full-screen add flow under the FAB; a pushed calendar
        // day presents the same flow as a card sheet so it reads as a modal
        // (user request 2026-07-16). See AddFoodPresentation for the
        // own-NavigationStack rationale.
        .modifier(AddFoodPresentation(asSheet: isPresented, isActive: $showingAdd, dayKey: dayKey))
        .task {
            #if DEBUG
            // Launch with `-showAddSheet 1` to open the add flow immediately.
            if isToday && !isPresented && UserDefaults.standard.bool(forKey: "showAddSheet") {
                showingAdd = true
            }
            #endif
        }
        .adaptiveSheet(item: $editing) { wrapper in
            QuantityEditSheet(entry: wrapper.entry)
        }
        .confirmDeleteEntry($pendingDelete, onConfirm: delete)
        .onChange(of: hasModalFlow) { _, active in modalFlowActive?.wrappedValue = active }
    }

    @ViewBuilder
    private var content: some View {
        if !isToday && entries.isEmpty {
            // Prototype: an empty past day shows only the gray empty card;
            // the add affordance stays for spec compliance.
            DayEmptyStateCard(isToday: false, dateLabel: dayLabel) { showingAdd = true }
                .padding(.top, 40)
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                DaySummaryCard(entries: entries, settings: settings, isToday: isToday, dayKey: dayKey)
                // Banner only on the pushed calendar day-detail (user decision
                // 2026-07-21); the Today tab root stays ad-free.
                if isPresented, let settings {
                    AdBannerView(settings: settings)
                        .padding(.top, 12)
                }
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
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                DiaryListCard(
                    entries: entries,
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

    private func delete(_ entry: DiaryEntry) {
        context.delete(entry)
        try? context.save()
    }
}

#Preview("Day detail") {
    NavigationStack {
        DayView(dayKey: DayKey.today, isToday: false)
    }
    .modelContainer(PreviewData.container)
}
