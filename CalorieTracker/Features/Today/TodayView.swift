import SwiftUI
import SwiftData

/// "Today" tab root: the shared day screen (`DayView`) for the current
/// local day, with its own navigation stack for pushed flows.
///
/// The day key is state, not a one-shot computation: an app left open (or
/// resumed from suspension) across midnight must start logging into the new
/// day, so the key refreshes via `onPossibleDayChange`. While an add/edit
/// modal is open the refresh is deferred (fix 2026-09-08): applying `.id`
/// immediately would recreate `DayView` and tear the flow down mid-typing.
/// The deferred entry still lands on the day the flow was opened for — that
/// day-stamping is intended and unchanged.
struct TodayView: View {
    @State private var dayKey = DayKey.today
    /// Mirrors `DayView`'s add/edit modal state (reported via binding).
    @State private var modalFlowActive = false
    /// Day refresh captured while a modal flow was open; applied on close.
    @State private var pendingDayKey: String?

    var body: some View {
        NavigationStack {
            DayView(dayKey: dayKey, isToday: true, modalFlowActive: $modalFlowActive)
                // Identity reset: @Query/@State inside DayView are seeded from
                // the day key in init and don't follow later param changes.
                .id(dayKey)
                // Pushed from the "last logged day" card (PreviousDayCard).
                // Registered here, on the stack root: a second destination
                // inside the pushed DayView would jam the stack.
                // The pushed day reports its add/edit modal too, so a midnight
                // `.id` reset never tears down a flow open on that screen.
                .navigationDestination(for: String.self) { key in
                    DayView(dayKey: key, isToday: key == dayKey, modalFlowActive: $modalFlowActive)
                }
        }
        .onPossibleDayChange {
            if modalFlowActive { pendingDayKey = DayKey.today } else { dayKey = DayKey.today }
        }
        .onChange(of: modalFlowActive) { _, active in
            guard !active, let pending = pendingDayKey else { return }
            pendingDayKey = nil
            dayKey = pending
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
