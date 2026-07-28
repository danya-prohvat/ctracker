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
    /// Per-nutrient mean daily intake over the visible period, respecting the
    /// per-day tracked set. Empty when nothing tracked has data → card hidden.
    @State private var nutrientAverages: [NutrientPeriodAverage] = []
    /// True when every day of the visible period is outside the free history
    /// window — the stats give way to the unlock CTA instead of leaking averages.
    @State private var periodFullyLocked = false
    @State private var selectedDayKey: String?
    @State private var showingPaywall = false

    init() {}

    private var settings: UserSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PillSegmentedControl(
                        options: CalendarViewMode.allCases,
                        label: { $0.label },
                        selection: $mode
                    )
                    .padding(.bottom, 16)

                    CalendarGridCard(
                        mode: mode,
                        anchor: anchor,
                        kcalByDay: kcalByDay,
                        calorieGoal: settings?.calorieGoal,
                        isDayLocked: { !isDayUnlocked($0) },
                        onStep: changeStep,
                        onTapDay: openDay
                    )
                    .animation(.easeInOut(duration: 0.2), value: mode)

                    if periodFullyLocked {
                        // Whole period behind the 30-day wall: offer the upgrade
                        // instead of averages computed over locked days.
                        CalendarHistoryLockedCard(onUnlock: { showingPaywall = true })
                            .padding(.top, 18)
                    } else {
                        CalendarStatsRow(
                            stats: periodStats,
                            goals: statGoals,
                            caption: periodCaption
                        )
                        .padding(.top, 18)

                        if let settings {
                            AdBannerView(settings: settings)
                                .padding(.top, 12)
                        }

                        if !nutrientAverages.isEmpty {
                            CalendarNutrientHistoryCard(
                                averages: nutrientAverages,
                                caption: periodCaption
                            )
                            .padding(.top, 12)
                        }

                        CalendarRingLegend()
                            .padding(.top, 16)
                        Text("Tap a day with a ring to view details.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textTertiary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
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
            .onChange(of: settings?.isPremium) {
                // Unlock the grid, stats and CTA right after a purchase, instead
                // of leaving stale locked-state @State until the next refetch.
                refetch()
            }
            .onChange(of: mode) {
                // Keep the user near where they were when the scale changes.
                withAnimation(.easeInOut(duration: 0.2)) {
                    anchor = Self.periodStart(of: mode.component, for: anchor)
                }
                refetch()
            }
        }
    }

    /// Daily targets the stat cards compare their averages against.
    private var statGoals: CalendarStatGoals {
        CalendarStatGoals(
            calories: settings?.calorieGoal,
            protein: settings?.proteinGoal,
            fat: settings?.fatGoal,
            carbs: settings?.carbGoal
        )
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
            nutrientAverages = []
            periodFullyLocked = false
            return
        }
        // Rings and averages cover only unlocked days, so a free user never sees
        // aggregated data from days behind the 30-day wall (spec §9). Locked cells
        // render their own lock via `isDayLocked`.
        let entries = CalendarPeriodData.fetchEntries(in: interval, context: context)
            .filter { isDayUnlocked($0.dayKey) }
        var totals: [String: Double] = [:]
        for entry in entries {
            totals[entry.dayKey, default: 0] += entry.calories
        }
        kcalByDay = totals
        periodStats = CalendarPeriodData.macroAverages(of: entries)
        nutrientAverages = settings.map {
            CalendarPeriodData.nutrientAverages(of: entries, settings: $0)
        } ?? []
        // The period is fully locked when even its newest day is out of the
        // window (a period holding today or recent days always has one unlocked).
        let newestKey = DayKey.string(from: interval.end.addingTimeInterval(-1))
        periodFullyLocked = !isDayUnlocked(newestKey)
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
