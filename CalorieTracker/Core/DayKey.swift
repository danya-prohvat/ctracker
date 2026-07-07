import Foundation

/// Local calendar-day key "yyyy-MM-dd" used to group diary entries (spec §2.3).
/// A key is stable across timezone changes because it is computed from the local
/// calendar at log time and then stored on the entry.
enum DayKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from key: String) -> Date? {
        formatter.date(from: key)
    }

    static var today: String { string(from: Date()) }
}
