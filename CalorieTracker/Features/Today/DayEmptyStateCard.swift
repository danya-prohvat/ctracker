import SwiftUI

/// Empty-state glass card for a day with no entries: the green variant for
/// Today, the gray variant for past days. For a brand-new user (`onScan`
/// set, nothing in the base yet) the Today card doubles as the start screen
/// with two CTAs — scan a barcode or add a food (user decision 2026-11-11:
/// the scanner used to be hidden behind "+" → Add food → a small tile). With
/// data elsewhere the Today root shows the "+" hint (`onAdd` nil, FAB); a
/// pushed day detail shows the inline "Add food" link.
struct DayEmptyStateCard: View {
    let isToday: Bool
    let dateLabel: String
    var onAdd: (() -> Void)? = nil
    var onScan: (() -> Void)? = nil

    private var showsActions: Bool { isToday && onScan != nil }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isToday ? Theme.emptyCircleFill : Color(hex: 0xF4F4F6))
                    .frame(width: 76, height: 76)
                Image(systemName: showsActions ? "barcode.viewfinder" : "fork.knife")
                    .font(.title2)
                    .foregroundStyle(isToday ? Theme.emptyCircleRing : Color(hex: 0xD0D0D5))
            }

            if isToday {
                Text("Nothing logged yet")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Group {
                    if showsActions {
                        Text("Scan a product barcode or add a food to log your first meal.")
                    } else if onAdd == nil {
                        Text("Tap the + button to add your first meal of the day.")
                    } else {
                        Text("Tap Add food below to log your first meal of the day.")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)
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

            if showsActions, let onScan, let onAdd {
                DayEmptyStateActions(onScan: onScan, onAdd: onAdd)
                    .padding(.top, 10)
            } else if let onAdd {
                Button(action: onAdd) {
                    AddFoodInlineLabel()
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressableScale)
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, showsActions ? 30 : 44)
        .padding(.horizontal, showsActions ? 20 : 28)
        .glassCard()
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            DayEmptyStateCard(isToday: true, dateLabel: "July 4", onAdd: {}, onScan: {})
            DayEmptyStateCard(isToday: true, dateLabel: "July 4")
            DayEmptyStateCard(isToday: true, dateLabel: "July 4") {}
            DayEmptyStateCard(isToday: false, dateLabel: "July 4") {}
        }
        .padding(20)
    }
    .background(AppBackground())
}
