import SwiftUI
import WidgetKit

/// Mirror of the app's `WidgetDaySnapshot` (Core/WidgetBridge.swift). The two
/// targets share no code — this JSON contract in the App Group defaults is the
/// entire interface; keep the fields in sync with the app side.
struct WidgetDaySnapshot: Codable {
    var dayKey: String = ""
    var consumedKcal: Double = 0
    var calorieGoal: Double?
    var updatedAt: Date = .distantPast
}

struct CalorieEntry: TimelineEntry {
    let date: Date
    let consumed: Double
    let goal: Double?
}

struct CalorieProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(date: Date(), consumed: 1460, goal: 2000)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        // The app pushes reloads on every change; the midnight refresh only
        // rolls the ring back to zero for the new day.
        let midnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [currentEntry()], policy: .after(midnight)))
    }

    private func currentEntry() -> CalorieEntry {
        let defaults = UserDefaults(suiteName: "group.com.prxfitness.calorietracker")
        var snapshot = WidgetDaySnapshot()
        if let data = defaults?.data(forKey: "widget.daySnapshot"),
           let decoded = try? JSONDecoder().decode(WidgetDaySnapshot.self, from: data) {
            snapshot = decoded
        }
        // A snapshot from a previous day means nothing is logged today yet.
        let consumed = snapshot.dayKey == Self.todayKey() ? snapshot.consumedKcal : 0
        return CalorieEntry(date: Date(), consumed: consumed, goal: snapshot.calorieGoal)
    }

    /// Same stable key format as the app's `DayKey` (fixed gregorian + POSIX).
    private static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct CalorieRingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CalorieRingWidget", provider: CalorieProvider()) { entry in
            CalorieWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetPalette.background }
        }
        .configurationDisplayName("Calories")
        .description("Today's calories at a glance.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

/// The few app-palette values the widget needs (targets share no code).
enum WidgetPalette {
    static let accent = Color(red: 0x43 / 255, green: 0xA2 / 255, blue: 0x6D / 255)
    static let warning = Color(red: 1.0, green: 0x95 / 255, blue: 0)
    static let text = Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255)
    static let secondary = Color(red: 0x8E / 255, green: 0x8E / 255, blue: 0x93 / 255)
    /// Faint top-leading green wash — the widget-sized echo of the app's aurora.
    static var background: some View {
        LinearGradient(
            colors: [Color(red: 0xE3 / 255, green: 0xF3 / 255, blue: 0xE9 / 255), .white],
            startPoint: .topLeading, endPoint: .bottom
        )
    }
}

struct CalorieWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CalorieEntry

    private var progress: Double {
        guard let goal = entry.goal, goal > 0 else { return 0 }
        return min(entry.consumed / goal, 1)
    }

    /// Over 105% of the goal — amber, never red (matches the app's ring rule).
    private var isOver: Bool {
        guard let goal = entry.goal, goal > 0 else { return false }
        return entry.consumed / goal > 1.05
    }

    private var ringColor: Color { isOver ? WidgetPalette.warning : WidgetPalette.accent }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: progress) {
                Text("kcal")
            } currentValueLabel: {
                Text(entry.consumed.rounded(), format: .number.precision(.fractionLength(0)))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        default:
            ZStack {
                Circle()
                    .stroke(ringColor.opacity(0.18), lineWidth: 11)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 1) {
                    Text(entry.consumed.rounded(), format: .number.precision(.fractionLength(0)))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(WidgetPalette.text)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    if let goal = entry.goal {
                        Text(verbatim: "/ \(Int(goal.rounded()))")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(WidgetPalette.secondary)
                    } else {
                        Text("kcal")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(WidgetPalette.secondary)
                    }
                }
                .padding(.horizontal, 14)
            }
            .padding(6)
        }
    }
}
