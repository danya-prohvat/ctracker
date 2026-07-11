import Foundation

/// Outcome of a network lookup (spec §7). Network failures are thrown instead,
/// so the caller can distinguish "offline" from "the product does not exist".
enum LookupResult {
    case found(ScanPrefill)
    case notFound
}

/// USDA FoodData Central configuration. Leave `apiKey` empty to disable the
/// USDA fallback entirely (Open Food Facts needs no key).
enum USDAConfig {
    static let apiKey = ""
}

/// Async barcode → nutrition lookup pipeline (spec §7). Network only — checking
/// the user's own product database first is the caller's responsibility.
///
/// Order: Open Food Facts (free, no key) → USDA FoodData Central (only when
/// `USDAConfig.apiKey` is set). All parsing is defensive: OFF fields may be
/// missing, or numbers encoded as strings.
enum BarcodeLookupService {

    /// Looks a barcode up online. Throws on transport / server errors so the
    /// caller can show an offline state with a Retry button.
    static func lookup(barcode: String) async throws -> LookupResult {
        if let prefill = try await lookupOpenFoodFacts(barcode: barcode) {
            return .found(prefill)
        }
        if let prefill = try await lookupUSDA(barcode: barcode) {
            return .found(prefill)
        }
        return .notFound
    }

    // MARK: - Open Food Facts

    private static func lookupOpenFoodFacts(barcode: String) async throws -> ScanPrefill? {
        guard
            let encoded = barcode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(encoded).json")
        else { return nil }

        var request = URLRequest(url: url)
        // OFF asks API consumers to identify themselves.
        request.setValue("CalorieTracker/1.0 (com.prxfitness.calorietracker; contact@utr.ua)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        // OFF answers 404 for unknown barcodes — that is "not found", not an error.
        if http.statusCode == 404 { return nil }
        guard (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }

        guard
            let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
            let product = root["product"] as? [String: Any]
        else { return nil }
        if let status = coerceDouble(root["status"]), status != 1 { return nil }

        let name = firstNonEmptyString(
            product["product_name"],
            product["product_name_en"],
            product["brands"]
        ) ?? ""

        let nutriments = product["nutriments"] as? [String: Any] ?? [:]

        // Energy: prefer kcal; fall back to kJ ÷ 4.184.
        var calories = coerceDouble(nutriments["energy-kcal_100g"])
        if calories == nil, let kilojoules = coerceDouble(nutriments["energy_100g"]) {
            calories = kilojoules / 4.184
        }

        var micros: [String: Double] = [:]
        for mapping in offMicroMappings {
            guard let raw = coerceDouble(nutriments[mapping.offKey]), raw.isFinite else { continue }
            let value = raw * mapping.multiplier
            if value > 0 { micros[mapping.nutrientID] = value }
        }

        return ScanPrefill(
            name: name,
            calories: sanitized(calories),
            protein: sanitized(coerceDouble(nutriments["proteins_100g"])),
            fat: sanitized(coerceDouble(nutriments["fat_100g"])),
            carbs: sanitized(coerceDouble(nutriments["carbohydrates_100g"])),
            micros: micros,
            barcode: barcode
        )
    }

    /// OFF nutriment key → our `NutrientDef.id`, with a multiplier converting
    /// OFF's grams into our fixed catalog unit (mg / µg where applicable).
    private struct OFFMicroMapping {
        let offKey: String
        let nutrientID: String
        let multiplier: Double
    }

    private static let offMicroMappings: [OFFMicroMapping] = [
        OFFMicroMapping(offKey: "fiber_100g", nutrientID: "fiber", multiplier: 1),
        OFFMicroMapping(offKey: "sugars_100g", nutrientID: "sugar", multiplier: 1),
        OFFMicroMapping(offKey: "saturated-fat_100g", nutrientID: "saturatedFat", multiplier: 1),
        OFFMicroMapping(offKey: "trans-fat_100g", nutrientID: "transFat", multiplier: 1),
        OFFMicroMapping(offKey: "cholesterol_100g", nutrientID: "cholesterol", multiplier: 1000),
        OFFMicroMapping(offKey: "sodium_100g", nutrientID: "sodium", multiplier: 1000),
        OFFMicroMapping(offKey: "calcium_100g", nutrientID: "calcium", multiplier: 1000),
        OFFMicroMapping(offKey: "iron_100g", nutrientID: "iron", multiplier: 1000),
        OFFMicroMapping(offKey: "potassium_100g", nutrientID: "potassium", multiplier: 1000),
        OFFMicroMapping(offKey: "magnesium_100g", nutrientID: "magnesium", multiplier: 1000),
        OFFMicroMapping(offKey: "zinc_100g", nutrientID: "zinc", multiplier: 1000),
        OFFMicroMapping(offKey: "vitamin-c_100g", nutrientID: "vitaminC", multiplier: 1000),
        OFFMicroMapping(offKey: "vitamin-a_100g", nutrientID: "vitaminA", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "vitamin-d_100g", nutrientID: "vitaminD", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "vitamin-b12_100g", nutrientID: "vitaminB12", multiplier: 1_000_000),
        OFFMicroMapping(offKey: "caffeine_100g", nutrientID: "caffeine", multiplier: 1000),
    ]

    // MARK: - USDA FoodData Central fallback

    private static func lookupUSDA(barcode: String) async throws -> ScanPrefill? {
        let key = USDAConfig.apiKey
        guard !key.isEmpty else { return nil }

        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: key),
            URLQueryItem(name: "query", value: barcode),
            URLQueryItem(name: "dataType", value: "Branded"),
        ]
        guard let url = components?.url else { return nil }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            // A bad key / server rejection should read as "not found", not "offline".
            return nil
        }

        guard
            let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
            let foods = root["foods"] as? [[String: Any]],
            let first = foods.first,
            let gtin = first["gtinUpc"] as? String,
            gtin.contains(barcode) || barcode.contains(gtin)
        else { return nil }

        let nutrients = first["foodNutrients"] as? [[String: Any]] ?? []

        let name = firstNonEmptyString(
            first["description"],
            first["brandName"],
            first["brandOwner"]
        ) ?? ""

        return ScanPrefill(
            name: name,
            calories: sanitized(usdaEnergyKcal(nutrients)),
            protein: sanitized(usdaValue(nutrients) { $0 == "protein" }),
            fat: sanitized(usdaValue(nutrients) { $0.contains("total lipid") || $0 == "fat" }),
            carbs: sanitized(usdaValue(nutrients) { $0.contains("carbohydrate") }),
            micros: [:],
            barcode: barcode
        )
    }

    /// Energy in kcal from a USDA `foodNutrients` array; prefers a KCAL entry,
    /// converts a kJ entry when that is all there is.
    private static func usdaEnergyKcal(_ nutrients: [[String: Any]]) -> Double? {
        var kilojoules: Double?
        for entry in nutrients {
            guard
                let name = (entry["nutrientName"] as? String)?.lowercased(),
                name.contains("energy"),
                let value = coerceDouble(entry["value"])
            else { continue }
            let unit = (entry["unitName"] as? String)?.uppercased() ?? ""
            if unit == "KCAL" { return value }
            if unit == "KJ" { kilojoules = value }
        }
        return kilojoules.map { $0 / 4.184 }
    }

    /// First nutrient value whose lowercased `nutrientName` matches.
    private static func usdaValue(
        _ nutrients: [[String: Any]],
        matching predicate: (String) -> Bool
    ) -> Double? {
        for entry in nutrients {
            if let name = (entry["nutrientName"] as? String)?.lowercased(),
               predicate(name),
               let value = coerceDouble(entry["value"]) {
                return value
            }
        }
        return nil
    }

    // MARK: - JSON coercion helpers

    /// APIs occasionally encode numbers as strings — accept both. (This is JSON
    /// decoding, not user text input, so `Format.parse` does not apply here.)
    private static func coerceDouble(_ any: Any?) -> Double? {
        switch any {
        case let number as NSNumber:
            return number.doubleValue
        case let string as String:
            return Double(string.replacingOccurrences(of: ",", with: "."))
        default:
            return nil
        }
    }

    /// Macro values must be finite and non-negative; anything else becomes 0.
    private static func sanitized(_ value: Double?) -> Double {
        guard let value, value.isFinite, value > 0 else { return 0 }
        return value
    }

    private static func firstNonEmptyString(_ values: Any?...) -> String? {
        for value in values {
            if let string = value as? String {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        return nil
    }
}
