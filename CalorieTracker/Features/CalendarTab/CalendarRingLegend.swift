import SwiftUI

/// One-line legend for the month-grid ring colors: a colored dot plus its
/// state word for each `CalendarRingState`, so the ring color is never the
/// only signal. Order matches the states' severity: on target · under · over.
struct CalendarRingLegend: View {
    private static let states: [CalendarRingState] = [.onTarget, .under, .over]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(Self.states.enumerated()), id: \.offset) { index, state in
                if index > 0 {
                    Text(verbatim: "·")
                        .foregroundStyle(Theme.textTertiary)
                }
                item(state)
            }
        }
        .font(.caption)
        .frame(maxWidth: .infinity)
    }

    private func item(_ state: CalendarRingState) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(state.color)
                .frame(width: 8, height: 8)
            // Already-localized word from the shared state type.
            Text(state.name)
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        AppBackground()
        CalendarRingLegend()
            .padding(16)
    }
}
