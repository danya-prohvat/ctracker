#if DEBUG
import SwiftUI
import UserNotifications

/// Debug-only sheet (Settings → Test → Scheduled notifications): lists every
/// pending local notification with its next fire date, so the smart-reminder
/// planning can be inspected on device/simulator.
struct PendingNotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct Item: Identifiable {
        let id: String
        let fireDate: Date?
        let body: String
    }

    @State private var items: [Item]?

    var body: some View {
        NavigationStack {
            Group {
                if let items {
                    if items.isEmpty {
                        ContentUnavailableView("Nothing scheduled", systemImage: "bell.slash")
                    } else {
                        List(items) { row($0) }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Scheduled")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh") { Task { await load() } }
                }
            }
            .task { await load() }
        }
    }

    /// Debug-only fixed pattern (user request 2026-07-21) — not locale-aware
    /// on purpose, so fire dates line up and compare at a glance.
    private static let fireDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter
    }()

    private func row(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let date = item.fireDate {
                Text(verbatim: Self.fireDateFormatter.string(from: date))
                    .font(.subheadline.weight(.semibold))
            } else {
                Text("No trigger date")
                    .font(.subheadline.weight(.semibold))
            }
            Text(item.body)
                .font(.footnote)
            Text(item.id)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func load() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        items = requests
            .map {
                Item(
                    id: $0.identifier,
                    fireDate: ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate(),
                    body: $0.content.body
                )
            }
            .sorted { ($0.fireDate ?? .distantFuture) < ($1.fireDate ?? .distantFuture) }
    }
}

#Preview {
    PendingNotificationsSheet()
}
#endif
