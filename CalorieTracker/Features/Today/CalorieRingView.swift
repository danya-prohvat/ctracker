import SwiftUI

/// Main calorie ring (prototype variant B): 132 pt, eaten kcal over "/ goal".
/// When no goal is set there is no progress arc (spec §2.5). The arc uses the
/// shared goal-progress color (`CalendarRingState`): neutral under, green on
/// target, amber over — never red (user decision 2026-07-10).
struct CalorieRingView: View {
    let consumed: Double
    let goal: Double?

    private var progress: Double {
        guard let goal, goal > 0 else { return 0 }
        return min(consumed / goal, 1)
    }

    private var ringColor: Color {
        CalendarRingState(consumed: consumed, target: goal).color
    }

    var body: some View {
        ZStack {
            ProgressRing(progress: progress, lineWidth: 12, color: ringColor)
            VStack(spacing: 1) {
                Text(Format.kcal(consumed))
                    .font(.stat(.title))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
                if let goal {
                    Text(verbatim: "/ \(Format.kcal(goal))")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Text("kcal")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(width: 132, height: 132)
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack(spacing: 24) {
            CalorieRingView(consumed: 1320, goal: 2000)
            CalorieRingView(consumed: 640, goal: nil)
        }
    }
}
