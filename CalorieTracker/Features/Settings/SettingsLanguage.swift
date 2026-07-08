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

    /// Display name shown in settings rows. Endonyms are verbatim on
    /// purpose — a language's own name never translates.
    var title: Text {
        self == .system ? Text("System") : Text(verbatim: endonym)
    }

    /// English exonym, verbatim by design: the picker lists every language
    /// as "English name + endonym" regardless of the UI language.
    var englishName: String {
        switch self {
        case .system: ""
        case .english: "English"
        case .ukrainian: "Ukrainian"
        case .russian: "Russian"
        case .arabic: "Arabic"
        }
    }

    /// The language's name in itself.
    var endonym: String {
        switch self {
        case .system: ""
        case .english: "English"
        case .ukrainian: "Українська"
        case .russian: "Русский"
        case .arabic: "العربية"
        }
    }
}
