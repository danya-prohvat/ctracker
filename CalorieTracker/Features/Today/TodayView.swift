import SwiftUI
import SwiftData

/// "Today" tab root: the shared day screen (`DayView`) for the current
/// local day, with its own navigation stack for pushed flows.
///
/// The day key is state, not a one-shot computation: an app left open (or
/// resumed from suspension) across midnight must start logging into the new
/// day, so the key refreshes via `onPossibleDayChange`.
struct TodayView: View {
    @State private var dayKey = DayKey.today

    var body: some View {
        NavigationStack {
            DayView(dayKey: dayKey, isToday: true)
                // Identity reset: @Query/@State inside DayView are seeded from
                // the day key in init and don't follow later param changes.
                .id(dayKey)
        }
        .onPossibleDayChange { dayKey = DayKey.today }
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
