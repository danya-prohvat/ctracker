import SwiftUI
import SwiftData

/// Calendar tab (spec §5): a week/month grid with per-day calorie progress
/// rings, day details reusing the shared `DayView`, and a premium gate on
/// history deeper than 30 days (spec §9). The segmented control switches the
/// whole view — grid, navigation step and the average cards — between the
/// current week and the current month (user request 2026-07-09).
struct CalendarTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [UserSettings]

    /// Time scale of the grid; the segmented control and stat-card taps drive it.
    @State private var mode: CalendarViewMode = .month
    /// First moment of the visible period (month-start or week-start).
    @State private var anchor: Date = CalendarTabView.periodStart(of: .month, for: Date())
    /// kcal totals per dayKey for the visible period. One fetch per period.
    @State private var kcalByDay: [String: Double] = [:]
    /// Per-day averages over the visible period, shown in the stat cards.
    @State private var periodStats: CalendarPeriodStats?
    @State private var selectedDayKey: String?
    @State private var showingPaywall = false

    init() {}

    private var settings: UserSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Picker("Calendar view", selection: $mode) {
                        Text("Week").tag(CalendarViewMode.week)
                        Text("Month").tag(CalendarViewMode.month)
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 16)

                    CalendarGridCard(
                        mode: mode,
                        anchor: anchor,
                        kcalByDay: kcalByDay,
                        calorieGoal: settings?.calorieGoal,
                        onStep: changeStep,
                        onTapDay: openDay
                    )
                    .animation(.easeInOut(duration: 0.2), value: mode)

                    CalendarStatsRow(
                        stats: periodStats,
                        caption: periodCaption,
                        onToggle: toggleMode
                    )
                    .padding(.top, 18)

                    CalendarRingLegend()
                        .padding(.top, 16)
                    Text("Tap a day with a ring to view details.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
            }
            .contentMargins(.bottom, 110, for: .scrollContent)
            .background(AppBackground())
            .largeTitleScreen("Calendar")
            .navigationDestination(item: $selectedDayKey) { key in
                DayView(dayKey: key, isToday: key == DayKey.today)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onAppear { refetch() }
            .onChange(of: mode) {
                // Keep the user near where they were when the scale changes.
                withAnimation(.easeInOut(duration: 0.2)) {
                    anchor = Self.periodStart(of: mode.component, for: anchor)
                }
                refetch()
            }
        }
    }

    /// Sub-caption for the stat cards: the period being averaged.
    private var periodCaption: Text {
        switch mode {
        case .month: Text(anchor, format: .dateTime.month(.wide))
        case .week: Text(verbatim: CalendarViewMode.weekRangeLabel(anchor))
        }
    }

    // MARK: - Actions

    private func openDay(_ dayKey: String) {
        if isDayUnlocked(dayKey) {
            selectedDayKey = dayKey
        } else {
            showingPaywall = true
        }
    }

    private func isDayUnlocked(_ dayKey: String) -> Bool {
        guard let settings else { return true }
        return PremiumGate.isDayUnlocked(dayKey: dayKey, settings: settings)
    }

    private func toggleMode() {
        mode = mode.toggled
    }

    /// Step one period (week or month) forward/back, respecting the mode.
    private func changeStep(_ delta: Int) {
        guard let shifted = Calendar.current.date(
            byAdding: mode.component, value: delta, to: anchor
        ) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            anchor = Self.periodStart(of: mode.component, for: shifted)
        }
        refetch()
    }

    // MARK: - Data

    /// The single fetch for the visible period. `dayKey` strings ("yyyy-MM-dd")
    /// sort lexicographically, so a string range covers the period even when it
    /// spans two Gregorian months.
    private func refetch() {
        guard let interval = Calendar.current.dateInterval(of: mode.component, for: anchor) else {
            kcalByDay = [:]
            periodStats = nil
            return
        }
        let entries = Self.fetchEntries(in: interval, context: context)
        var totals: [String: Double] = [:]
        for entry in entries {
            totals[entry.dayKey, default: 0] += entry.calories
        }
        kcalByDay = totals
        periodStats = Self.averages(of: entries)
    }

    /// Averages entries over the distinct days they cover (nil when empty).
    private static func averages(of entries: [DiaryEntry]) -> CalendarPeriodStats? {
        guard !entries.isEmpty else { return nil }
        var kcalPerDay: [String: Double] = [:]
        var totalProtein: Double = 0
        for entry in entries {
            kcalPerDay[entry.dayKey, default: 0] += entry.calories
            totalProtein += entry.protein
        }
        let dayCount = Double(kcalPerDay.count)
        return CalendarPeriodStats(
            avgCalories: kcalPerDay.values.reduce(0, +) / dayCount,
            avgProtein: totalProtein / dayCount
        )
    }

    private static func fetchEntries(in interval: DateInterval, context: ModelContext) -> [DiaryEntry] {
        let startKey = DayKey.string(from: interval.start)
        // `interval.end` is the exclusive start of the next period.
        let endKey = DayKey.string(from: interval.end.addingTimeInterval(-1))
        let descriptor = FetchDescriptor<DiaryEntry>(
            predicate: #Predicate { $0.dayKey >= startKey && $0.dayKey <= endKey }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Start of the calendar period (`.weekOfYear` or `.month`) containing `date`.
    private static func periodStart(of component: Calendar.Component, for date: Date) -> Date {
        Calendar.current.dateInterval(of: component, for: date)?.start ?? date
    }
}

#Preview {
    CalendarTabView()
        .modelContainer(PreviewData.container)
}
