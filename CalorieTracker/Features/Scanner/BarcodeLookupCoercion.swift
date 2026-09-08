import Foundation

/// JSON coercion helpers for the OFF lookup (split out of
/// `BarcodeLookupService.swift` to keep it under the 200-line limit).
extension BarcodeLookupService {

    /// APIs occasionally encode numbers as strings — accept both. (This is JSON
    /// decoding, not user text input, so `Format.parse` does not apply here.)
    static func coerceDouble(_ any: Any?) -> Double? {
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
    static func sanitized(_ value: Double?) -> Double {
        guard let value, value.isFinite, value > 0 else { return 0 }
        return value
    }

    static func firstNonEmptyString(_ values: Any?...) -> String? {
        for value in values {
            if let string = value as? String {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        return nil
    }
}
