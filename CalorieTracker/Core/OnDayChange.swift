import SwiftUI

/// Runs an action whenever the local calendar day may have changed: on
/// `NSCalendarDayChanged` and on every scene activation — the notification
/// is not replayed after a suspension, so both signals are needed (Today fix
/// 2026-07-28). Callers re-derive their "today" state and no-op when the day
/// is in fact unchanged.
private struct OnDayChange: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .task {
                for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                    action()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { action() }
            }
    }
}

extension View {
    /// Calls `action` when the local day may have rolled over (midnight, or a
    /// return from suspension). Any view that keeps "today" in state must
    /// refresh it here — a render-time `DayKey.today` goes stale overnight.
    func onPossibleDayChange(perform action: @escaping () -> Void) -> some View {
        modifier(OnDayChange(action: action))
    }
}
