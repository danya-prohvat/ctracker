import Foundation

/// Outcome of a network lookup (spec §7). Network failures are thrown instead,
/// so the caller can distinguish "offline" from "the product does not exist".
enum LookupResult {
    case found(ScanPrefill)
    case notFound
}

/// Async barcode → nutrition lookup pipeline (spec §7). Network only — checking
/// the user's own product database first is the caller's responsibility.
///
/// Source: Open Food Facts (free, no key). All parsing is defensive: OFF
/// fields may be missing, or numbers encoded as strings. (A USDA FoodData
/// Central fallback existed briefly and was removed by user decision
/// 2026-07-12 — OFF alone covers the target markets.)
enum BarcodeLookupService {

    /// Looks a barcode up online. Throws on transport / server errors so the
    /// caller can show an offline state with a Retry button.
    static func lookup(barcode: String) async throws -> LookupResult {
        if let prefill = try await lookupOpenFoodFacts(barcode: barcode) {
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
        for mapping in OFFMicroMapping.all {
            guard micros[mapping.nutrientID] == nil,
                  let raw = coerceDouble(nutriments[mapping.offKey]), raw.isFinite
            else { continue }
            let value = raw * mapping.multiplier
            if value > 0 { micros[mapping.nutrientID] = value }
        }
        if let sodiumGrams = resolvedSodiumGrams(nutriments), sodiumGrams > 0 {
            micros["sodium"] = sodiumGrams * 1000 // catalog unit is mg
        }

        return ScanPrefill(
            name: name,
            basis: detectedBasis(product),
            calories: sanitized(calories),
            protein: sanitized(coerceDouble(nutriments["proteins_100g"])),
            fat: sanitized(coerceDouble(nutriments["fat_100g"])),
            carbs: sanitized(coerceDouble(nutriments["carbohydrates_100g"])),
            micros: micros,
            barcode: barcode
        )
    }

    /// Detects whether an OFF product is a liquid, so the form opens on
    /// "per 100 ml" instead of "per 100 g". Signals, most reliable first:
    /// nutrition declared per 100 ml, a volume quantity unit ("0,5 l", "33 cl"),
    /// or a beverages food group / category. Defaults to grams.
    private static func detectedBasis(_ product: [String: Any]) -> Basis {
        if let per = (product["nutrition_data_per"] as? String)?.lowercased(),
           per.contains("ml") {
            return .per100ml
        }
        if let unit = (product["product_quantity_unit"] as? String)?.lowercased(),
           ["ml", "cl", "dl", "l"].contains(unit) {
            return .per100ml
        }
        if let quantity = (product["quantity"] as? String)?.lowercased() {
            let compact = quantity.replacingOccurrences(of: " ", with: "")
            // Covers "500ml", "33cl", "0,5l" — and "1gal", since it ends in "l" too.
            if compact.hasSuffix("l") || compact.hasSuffix("floz") {
                return .per100ml
            }
        }
        let groupSources: [[String]] = [
            product["food_groups_tags"] as? [String] ?? [],
            product["categories_tags"] as? [String] ?? [],
            (product["pnns_groups_1"] as? String).map { [$0.lowercased()] } ?? [],
        ]
        if groupSources.joined().contains(where: { $0.contains("beverage") || $0.contains("drink") }) {
            return .per100ml
        }
        return .per100g
    }

    /// Sodium per 100 g/ml in grams, cross-checked against salt. Physically
    /// sodium = salt × 0.4, so a card where sodium exceeds salt has a unit
    /// mix-up (mg typed into the grams field — a common OFF error); the salt
    /// field wins then. Falls back to deriving from salt when sodium is
    /// missing entirely.
    private static func resolvedSodiumGrams(_ nutriments: [String: Any]) -> Double? {
        let sodium = coerceDouble(nutriments["sodium_100g"])
        let salt = coerceDouble(nutriments["salt_100g"])
        switch (sodium, salt) {
        case let (sodium?, salt?): return sodium > salt ? salt * 0.4 : sodium
        case let (sodium?, nil): return sodium
        case let (nil, salt?): return salt * 0.4
        case (nil, nil): return nil
        }
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
