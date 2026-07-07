import SwiftUI
import SwiftData

/// Calendar tab (spec §5): month grid with per-day calorie progress rings,
/// day details reusing the shared `DayView`, and a premium gate on history
/// deeper than 30 days (spec §9).
struct CalendarTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [UserSettings]

    /// First moment of the displayed month (user's calendar).
    @State private var displayedMonth: Date = CalendarTabView.monthStart(Date())
    /// kcal totals per dayKey for the displayed month. Filled by exactly one
    /// fetch per visible month (spec: one efficient query per visible month).
    @State private var kcalByDay: [String: Double] = [:]
    @State private var weekStats: CalendarWeekStats?
    @State private var selectedDayKey: String?
    @State private var showingPaywall = false

    init() {}

    private var settings: UserSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    CalendarMonthCard(
                        displayedMonth: displayedMonth,
                        kcalByDay: kcalByDay,
                        calorieGoal: settings?.calorieGoal,
                        onChangeMonth: changeMonth,
                        onTapDay: openDay
                    )
                    CalendarWeekStatsRow(stats: weekStats)
                        .padding(.top, 18)
                    Text("Tap a day with a ring to view details.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                }
                .padding(.horizontal, 16)
            }
            .contentMargins(.bottom, 110, for: .scrollContent)
            .background(AppBackground())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedDayKey) { key in
                DayView(dayKey: key, isToday: key == DayKey.today)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onAppear {
                refetchMonth()
                refetchWeek()
            }
            .onChange(of: displayedMonth) {
                refetchMonth()
            }
        }
    }

    // MARK: - Header (prototype: 30px bold, margins 6/2/20)

    private var header: some View {
        Text("Calendar")
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.top, 6)
            .padding(.horizontal, 2)
            .padding(.bottom, 20)
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

    private func changeMonth(_ delta: Int) {
        guard let shifted = Calendar.current.date(
            byAdding: .month, value: delta, to: displayedMonth
        ) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = Self.monthStart(shifted)
        }
    }

    // MARK: - Data

    /// The single fetch for the visible month. `dayKey` strings ("yyyy-MM-dd")
    /// sort lexicographically, so a string range covers the whole month even if
    /// the user's calendar month spans two Gregorian months.
    private func refetchMonth() {
        guard let interval = Calendar.current.dateInterval(of: .month, for: displayedMonth) else {
            kcalByDay = [:]
            return
        }
        var totals: [String: Double] = [:]
        for entry in Self.fetchEntries(in: interval, context: context) {
            totals[entry.dayKey, default: 0] += entry.calories
        }
        kcalByDay = totals
    }

    /// Small second fetch for the current calendar week (it may span two months).
    private func refetchWeek() {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else {
            weekStats = nil
            return
        }
        let entries = Self.fetchEntries(in: interval, context: context)
        guard !entries.isEmpty else {
            weekStats = nil
            return
        }
        var kcalPerDay: [String: Double] = [:]
        var totalProtein: Double = 0
        for entry in entries {
            kcalPerDay[entry.dayKey, default: 0] += entry.calories
            totalProtein += entry.protein
        }
        let dayCount = Double(kcalPerDay.count)
        weekStats = CalendarWeekStats(
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

    private static func monthStart(_ date: Date) -> Date {
        Calendar.current.dateInterval(of: .month, for: date)?.start ?? date
    }
}

#Preview {
    CalendarTabView()
        .modelContainer(PreviewData.container)
}
