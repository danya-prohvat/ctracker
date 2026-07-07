import SwiftUI
import SwiftData

/// "Today" tab root: the shared day screen (`DayView`) for the current
/// local day, with its own navigation stack for pushed flows.
struct TodayView: View {
    var body: some View {
        NavigationStack {
            DayView(dayKey: DayKey.today, isToday: true)
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewData.container)
}
