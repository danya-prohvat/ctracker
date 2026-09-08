#if DEBUG
import Foundation
import SwiftData

/// Debug-only curated "screenshot day". Launched with `-seedScreenshotDay 1` it
/// replaces TODAY's diary with a fixed full day for App Store screenshots:
/// ~1548 kcal of an 1850 goal (≈84%, green zone), macro rings intentionally
/// uneven — protein ≈90%, fat ≈60%, carbs ≈75%. Idempotent: re-launching with
/// the flag rebuilds the same day.
enum ScreenshotSeeder {
    @MainActor
    static func seedIfRequested(_ context: ModelContext) {
        guard UserDefaults.standard.bool(forKey: "seedScreenshotDay") else { return }
        seed(context)
    }

    /// One logged item: per-100 snapshot values + portion + log time.
    struct Item {
        let name: String
        let calories, protein, fat, carbs: Double
        let micros: [String: Double]
        let quantity: Double
        let hour: Int
        let minute: Int
    }

    /// Breakfast → lunch → snack → dinner; totals hit the ring targets above.
    /// Micros are tuned so the Nutrients section shows a deliberate mix:
    /// iron ~70%, magnesium ~85%, B12 100% ✓, vitamin D ~40%, calcium ~60%,
    /// zinc ~55%, sodium (limit) ~50%, fiber ~73%, sugar ~65%, sat fat ~41%.
    static let items: [Item] = [
        .init(name: "Oatmeal", calories: 380, protein: 13, fat: 7, carbs: 67,
              micros: ["fiber": 10, "sugar": 1, "saturatedFat": 1.2, "iron": 4.7,
                       "magnesium": 177, "calcium": 120, "zinc": 2.3, "vitaminD": 1],
              quantity: 60, hour: 8, minute: 5),
        .init(name: "Banana", calories: 90, protein: 1.1, fat: 0.3, carbs: 23,
              micros: ["fiber": 2.6, "sugar": 12, "potassium": 358, "vitaminC": 8.7,
                       "iron": 0.3, "magnesium": 27, "calcium": 5, "zinc": 0.15],
              quantity: 150, hour: 8, minute: 15),
        .init(name: "Chicken breast", calories: 166, protein: 31, fat: 3.6, carbs: 0,
              micros: ["saturatedFat": 1, "sodium": 74, "potassium": 256, "iron": 0.7,
                       "magnesium": 29, "calcium": 5, "zinc": 1, "vitaminB12": 0.3],
              quantity: 150, hour: 13, minute: 0),
        .init(name: "Rice", calories: 130, protein: 2.7, fat: 0.3, carbs: 28,
              micros: ["fiber": 0.4, "sodium": 1, "iron": 1.2, "magnesium": 12,
                       "calcium": 10, "zinc": 0.5],
              quantity: 100, hour: 13, minute: 5),
        .init(name: "Salad", calories: 90, protein: 1.5, fat: 7, carbs: 5,
              micros: ["fiber": 1.8, "sugar": 2.5, "saturatedFat": 1, "sodium": 280,
                       "iron": 1, "magnesium": 20, "calcium": 80, "zinc": 0.05],
              quantity: 200, hour: 13, minute: 10),
        .init(name: "Greek yogurt", calories: 60, protein: 10, fat: 0.4, carbs: 3.6,
              micros: ["sugar": 3.2, "saturatedFat": 0.1, "calcium": 250, "sodium": 36,
                       "magnesium": 11, "iron": 0.1, "zinc": 0.6, "vitaminB12": 0.5,
                       "vitaminD": 0.5],
              quantity: 170, hour: 16, minute: 30),
        .init(name: "Salmon", calories: 210, protein: 20, fat: 13, carbs: 0,
              micros: ["saturatedFat": 3.1, "sodium": 59, "vitaminD": 5.5,
                       "vitaminB12": 0.92, "iron": 0.8, "magnesium": 30, "calcium": 15,
                       "zinc": 0.4],
              quantity: 120, hour: 19, minute: 30),
        .init(name: "Potato", calories: 93, protein: 2.5, fat: 0.1, carbs: 21,
              micros: ["fiber": 2.2, "sugar": 1.2, "potassium": 535, "sodium": 120,
                       "iron": 1.3, "magnesium": 20, "calcium": 20, "zinc": 0.3],
              quantity: 300, hour: 19, minute: 40),
    ]

    /// Diary names per shot language (`-screenshotLanguage`); English is the
    /// canonical key. Unlisted languages fall back to English.
    static let localizedNames: [String: [String: String]] = [
        "de": ["Oatmeal": "Haferflocken", "Banana": "Banane",
               "Chicken breast": "H\u{00E4}hnchenbrust", "Rice": "Reis",
               "Salad": "Salat", "Greek yogurt": "Griechischer Joghurt",
               "Salmon": "Lachs", "Potato": "Kartoffeln"],
        "es": ["Oatmeal": "Copos de avena", "Banana": "Pl\u{00E1}tano",
               "Chicken breast": "Pechuga de pollo", "Rice": "Arroz",
               "Salad": "Ensalada mixta", "Greek yogurt": "Yogur griego",
               "Salmon": "Salm\u{00F3}n", "Potato": "Patatas"],
        "fr": ["Oatmeal": "Flocons d'avoine", "Banana": "Banane",
               "Chicken breast": "Blanc de poulet", "Rice": "Riz",
               "Salad": "Salade verte", "Greek yogurt": "Yaourt grec",
               "Salmon": "Saumon", "Potato": "Pommes de terre"],
        "ja": ["Oatmeal": "オートミール", "Banana": "バナナ",
               "Chicken breast": "鶏むね肉", "Rice": "ご飯",
               "Salad": "サラダ", "Greek yogurt": "ギリシャヨーグルト",
               "Salmon": "サーモン", "Potato": "じゃがいも"],
        "ar": ["Oatmeal": "شوفان", "Banana": "موز",
               "Chicken breast": "صدر دجاج", "Rice": "أرز",
               "Salad": "سلطة خضراء", "Greek yogurt": "زبادي يوناني",
               "Salmon": "سلمون", "Potato": "بطاطس"],
    ]

    static func localizedName(_ item: Item) -> String {
        let lang = UserDefaults.standard.string(forKey: "screenshotLanguage") ?? "en"
        return localizedNames[lang]?[item.name] ?? item.name
    }

    /// Nutrients section rows (catalog order): the free four plus six premium
    /// vitamins/minerals — 10 rows, a deliberate reached/short mix.
    private static let trackedNutrients = [
        "calcium", "magnesium", "sodium", "iron", "zinc",
        "vitaminD", "vitaminB12", "fiber", "sugar", "saturatedFat",
    ]

    @MainActor
    private static func seed(_ context: ModelContext) {
        let settings = UserSettings.current(in: context)
        settings.onboardingCompleted = true
        // Shot language: only when `-screenshotLanguage <code>` is explicitly
        // passed — it pins the UI strings (via `languageCode`) and the
        // number/date formatting locale, so the host simulator locale never
        // leaks into a frame. The AppleLanguages/AppleLocale pins go into the
        // VOLATILE arguments domain, never persistent defaults (fix
        // 2026-09-08: the old persistent write kept forcing "en" on every
        // later argument-less run, with no way back). A pre-fix leak of
        // AppleLocale is cleaned here — nothing else in the app writes it.
        UserDefaults.standard.removeObject(forKey: "AppleLocale")
        if let lang = UserDefaults.standard.string(forKey: "screenshotLanguage") {
            settings.languageCode = lang
            let locales = ["en": "en_US", "uk": "uk_UA", "cs": "cs_CZ", "da": "da_DK",
                           "el": "el_GR", "he": "he_IL", "ja": "ja_JP", "ko": "ko_KR",
                           "zh": "zh_CN", "vi": "vi_VN", "ms": "ms_MY", "hi": "hi_IN",
                           "sv": "sv_SE", "nb": "nb_NO", "ar": "ar_EG@numbers=latn", "pt-BR": "pt_BR"]
            var args = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
            args["AppleLanguages"] = [lang]
            args["AppleLocale"] = locales[lang] ?? lang
            UserDefaults.standard.setVolatileDomain(args, forName: UserDefaults.argumentDomain)
        }
        settings.netCarbsEnabled = false
        // Premium look: vitamins/minerals tracked, no locks or ads in frame.
        settings.isPremium = true
        // `-trackAllNutrients 1` widens tracking to the full catalog — used by
        // the scanned-card frame so every OFF value gets a visible field.
        settings.enabledNutrients = UserDefaults.standard.bool(forKey: "trackAllNutrients")
            ? NutrientCatalog.all.map(\.id)
            : trackedNutrients
        // Catalog default norms in every goal row (Iron 18 mg, Sugar 50 g, …).
        settings.nutrientGoalOverrides = [:]
        // Empty change log → views fall back to the live set for every day.
        settings.nutrientTrackingLog = []
        settings.calorieGoal = 1850
        settings.proteinGoal = 122   // 110 g logged → ~90%
        settings.fatGoal = 68        // 41 g logged → ~60%
        settings.carbGoal = 242      // 182 g logged → ~75%

        // Rebuild the whole diary and product list (object-by-object —
        // CloudKit-safe, see CLAUDE.md); stale names from another shot
        // language must not linger in "My products" / Recent chips.
        let key = DayKey.today
        let old = (try? context.fetch(FetchDescriptor<DiaryEntry>())) ?? []
        for entry in old { context.delete(entry) }
        let oldProducts = (try? context.fetch(FetchDescriptor<Product>())) ?? []
        for product in oldProducts { context.delete(product) }

        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: Date())
        for item in items {
            let date = cal.date(bySettingHour: item.hour, minute: item.minute,
                                second: 0, of: dayStart) ?? dayStart
            context.insert(DiaryEntry(
                loggedAt: date, dayKey: key,
                productName: localizedName(item), basis: .per100g, quantity: item.quantity,
                per100Calories: item.calories, per100Protein: item.protein,
                per100Fat: item.fat, per100Carbs: item.carbs,
                per100Micros: item.micros,
                productID: product(for: item, in: context, loggedAt: date).id))
        }
        seedHistory(context, goal: settings.calorieGoal ?? 1850)
        try? context.save()
    }

    /// Reuse a same-named product or create one, so "My products" matches the day.
    @MainActor
    private static func product(for item: Item, in context: ModelContext,
                                loggedAt: Date) -> Product {
        let name = localizedName(item)
        if let existing = try? context.fetch(FetchDescriptor<Product>(
            predicate: #Predicate { $0.name == name })).first {
            existing.lastQuantity = item.quantity
            existing.lastLoggedAt = loggedAt
            return existing
        }
        let p = Product(name: name, basis: .per100g,
                        calories: item.calories, protein: item.protein,
                        fat: item.fat, carbs: item.carbs, micros: item.micros,
                        lastQuantity: item.quantity, lastLoggedAt: loggedAt)
        context.insert(p)
        return p
    }

}
#endif
