import SwiftUI

/// App language override choices. `nil` code = follow the system language.
/// Cases are ordered alphabetically by English name to match the picker list.
enum SettingsLanguage: String, CaseIterable, Identifiable {
    case system
    case arabic = "ar"
    case bangla = "bn"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case croatian = "hr"
    case czech = "cs"
    case danish = "da"
    case dutch = "nl"
    case english = "en"
    case finnish = "fi"
    case french = "fr"
    case german = "de"
    case greek = "el"
    case hebrew = "he"
    case hindi = "hi"
    case hungarian = "hu"
    case indonesian = "id"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case malay = "ms"
    case norwegian = "nb"
    case polish = "pl"
    case portugueseBrazil = "pt-BR"
    case portuguesePortugal = "pt-PT"
    case romanian = "ro"
    case russian = "ru"
    case slovak = "sk"
    case slovenian = "sl"
    case spanishSpain = "es-ES"
    case swedish = "sv"
    case thai = "th"
    case turkish = "tr"
    case ukrainian = "uk"
    case urdu = "ur"
    case vietnamese = "vi"

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
    var englishName: String { names.english }

    /// The language's name in itself.
    var endonym: String { names.endonym }

    /// Single source of truth for both names, so each language is listed once.
    /// Verbatim by design — neither the exonym nor the endonym is localized.
    private var names: (english: String, endonym: String) {
        switch self {
        case .system: ("", "")
        case .arabic: ("Arabic", "العربية")
        case .bangla: ("Bangla", "বাংলা")
        case .chineseSimplified: ("Chinese (Simplified)", "简体中文")
        case .chineseTraditional: ("Chinese (Traditional)", "繁體中文")
        case .croatian: ("Croatian", "Hrvatski")
        case .czech: ("Czech", "Čeština")
        case .danish: ("Danish", "Dansk")
        case .dutch: ("Dutch", "Nederlands")
        case .english: ("English", "English")
        case .finnish: ("Finnish", "Suomi")
        case .french: ("French", "Français")
        case .german: ("German", "Deutsch")
        case .greek: ("Greek", "Ελληνικά")
        case .hebrew: ("Hebrew", "עברית")
        case .hindi: ("Hindi", "हिन्दी")
        case .hungarian: ("Hungarian", "Magyar")
        case .indonesian: ("Indonesian", "Bahasa Indonesia")
        case .italian: ("Italian", "Italiano")
        case .japanese: ("Japanese", "日本語")
        case .korean: ("Korean", "한국어")
        case .malay: ("Malay", "Bahasa Melayu")
        case .norwegian: ("Norwegian", "Norsk Bokmål")
        case .polish: ("Polish", "Polski")
        case .portugueseBrazil: ("Portuguese (Brazil)", "Português (Brasil)")
        case .portuguesePortugal: ("Portuguese (Portugal)", "Português (Portugal)")
        case .romanian: ("Romanian", "Română")
        case .russian: ("Russian", "Русский")
        case .slovak: ("Slovak", "Slovenčina")
        case .slovenian: ("Slovenian", "Slovenščina")
        case .spanishSpain: ("Spanish (Spain)", "Español (España)")
        case .swedish: ("Swedish", "Svenska")
        case .thai: ("Thai", "ไทย")
        case .turkish: ("Turkish", "Türkçe")
        case .ukrainian: ("Ukrainian", "Українська")
        case .urdu: ("Urdu", "اردو")
        case .vietnamese: ("Vietnamese", "Tiếng Việt")
        }
    }
}
