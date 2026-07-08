import SwiftUI

/// Empty-state glass card for a day with no entries: the green variant for
/// Today, the gray variant for past days. An optional add affordance keeps
/// the day editable where the FAB is absent (calendar day details).
struct DayEmptyStateCard: View {
    let isToday: Bool
    let dateLabel: String
    var onAdd: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isToday ? Theme.emptyCircleFill : Color(hex: 0xF4F4F6))
                    .frame(width: 76, height: 76)
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(isToday ? Theme.emptyCircleRing : Color(hex: 0xD0D0D5))
            }

            if isToday {
                Text("Nothing logged yet")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("Tap the + button to add your first meal of the day.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 220)
            } else {
                Text("Nothing logged this day")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("There are no entries for \(dateLabel).")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 220)
            }

            if let onAdd {
                Button(action: onAdd) {
                    AddFoodInlineLabel()
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 28)
        .glassCard()
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 20) {
            DayEmptyStateCard(isToday: true, dateLabel: "July 4")
            DayEmptyStateCard(isToday: false, dateLabel: "July 4") {}
        }
        .padding(20)
    }
}
