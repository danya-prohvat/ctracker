import SwiftUI
import SwiftData

/// "Today" tab root: the shared day screen (`DayView`) for the current
/// local day, with its own navigation stack for pushed flows.
///
/// The day key is state, not a one-shot computation: an app left open (or
/// resumed from suspension) across midnight must start logging into the new
/// day, so the key refreshes on the calendar-day-change notification and on
/// every scene activation.
struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var dayKey = DayKey.today

    var body: some View {
        NavigationStack {
            DayView(dayKey: dayKey, isToday: true)
                // Identity reset: @Query/@State inside DayView are seeded from
                // the day key in init and don't follow later param changes.
                .id(dayKey)
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                dayKey = DayKey.today
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // The day-changed notification isn't replayed after a suspension,
            // so re-check whenever the app comes back to the foreground.
            if phase == .active { dayKey = DayKey.today }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewData.container)
}

#Preview("RTL ar") {
    TodayView()
        .modelContainer(PreviewData.container)
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
}
