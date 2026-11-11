import SwiftUI
import SwiftData

/// Section header ("Yesterday · 3 items · 1 240 kcal") plus a card with up
/// to four compact diary rows and an "Open this day" footer; the whole card
/// is a navigation link to the day detail (`TodayView` registers the
/// destination). Beyond the free 30-day window the rows are replaced by the
/// shared history-lock card — aggregates of locked days are not previewed.
struct PreviousDayCard: View {
    let dayKey: String
    let title: String
    let unitSystem: UnitSystem
    let isUnlocked: Bool

    @Query private var entries: [DiaryEntry]
    @State private var showingPaywall = false

    private static let previewRows = 4

    init(dayKey: String, title: String, unitSystem: UnitSystem, isUnlocked: Bool) {
        self.dayKey = dayKey
        self.title = title
        self.unitSystem = unitSystem
        self.isUnlocked = isUnlocked
        let key = dayKey
        _entries = Query(filter: #Predicate<DiaryEntry> { $0.dayKey == key },
                         sort: \.loggedAt, order: .forward)
    }

    private var totalCalories: Double { entries.reduce(0) { $0 + $1.calories } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text("^[\(entries.count) item](inflect: true) · \(Format.kcal(totalCalories)) kcal")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)

            if isUnlocked {
                NavigationLink(value: dayKey) { card }
                    .buttonStyle(.pressableCard)
            } else {
                CalendarHistoryLockedCard(onUnlock: { showingPaywall = true })
            }
        }
        .adaptiveSheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            ForEach(entries.prefix(Self.previewRows)) { entry in
                row(entry)
                Rectangle()
                    .fill(Theme.separator)
                    .frame(height: 1)
            }
            HStack(spacing: 6) {
                Text("Open this day")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Theme.accentIcon)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
        }
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        .glassCard()
    }

    private func row(_ entry: DiaryEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.productName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(Format.quantity(entry.quantity, basis: entry.basis, unitSystem: unitSystem))
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 8)
            Text("\(Format.kcal(entry.calories)) kcal")
                .font(.stat(.subheadline, .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            PreviousDaySection(todayKey: DayKey.today, settings: nil, unitSystem: .metric)
                .padding(20)
        }
        .background(AppBackground())
    }
    .modelContainer(PreviewData.container)
}
