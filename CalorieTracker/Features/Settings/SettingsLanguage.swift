import SwiftUI

/// App language override choices. `nil` code = follow the system language.
enum SettingsLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case ukrainian = "uk"
    case russian = "ru"
    case arabic = "ar"

    var id: String { rawValue }

    /// Language code stored in settings; `nil` = follow the system.
    var code: String? { self == .system ? nil : rawValue }

    init(code: String?) {
        self = code.flatMap { SettingsLanguage(rawValue: $0) } ?? .system
    }

    /// Display name. Endonyms are verbatim on purpose — a language's own
    /// name never translates.
    var title: Text {
        switch self {
        case .system: Text("System")
        case .english: Text(verbatim: "English")
        case .ukrainian: Text(verbatim: "Українська")
        case .russian: Text(verbatim: "Русский")
        case .arabic: Text(verbatim: "العربية")
        }
    }
}
