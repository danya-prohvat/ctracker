import Foundation

/// Validation for hand-typed barcodes (manual entry, user decision
/// 2026-09-28). A camera never produces garbage, a keyboard does — so the
/// field is digits-only and the lookup button unlocks only for a plausible
/// GTIN. Typos land in `.badCheckDigit` before any network round-trip.
enum BarcodeInput {
    static let maxDigits = 14

    enum Verdict: Equatable {
        case tooShort        // keep typing
        case badLength       // 9–11 digits: no barcode symbology has these
        case badCheckDigit   // right length, wrong last digit → a typo
        case valid
    }

    /// Digits only, capped. Any decimal digit is normalized to ASCII, so an
    /// Arabic-Indic keypad works too; letters, spaces and dashes are dropped.
    static func sanitized(_ raw: String) -> String {
        let digits = raw.compactMap { char -> String? in
            guard let value = char.wholeNumberValue, (0...9).contains(value) else { return nil }
            return String(value)
        }
        return digits.prefix(maxDigits).joined()
    }

    /// EAN-8 is accepted as typed: an 8-digit UPC-E shares the length but not
    /// the check maths, so verifying it would reject real US codes.
    static func verdict(_ code: String) -> Verdict {
        switch code.count {
        case ..<8: return .tooShort
        case 8: return .valid
        case 12, 13, 14: return hasValidCheckDigit(code) ? .valid : .badCheckDigit
        default: return .badLength
        }
    }

    /// The form the camera would have reported: UPC-A comes off the sensor as
    /// an EAN-13 with a leading zero, so a typed 12-digit code is padded the
    /// same way and the local dedupe + OFF lookup behave identically.
    static func normalizedForLookup(_ code: String) -> String {
        code.count == 12 ? "0" + code : code
    }

    /// GTIN mod-10 check: weights 3,1,3,1… from the right over the body digits.
    static func hasValidCheckDigit(_ code: String) -> Bool {
        let digits = code.compactMap { $0.wholeNumberValue }
        guard digits.count == code.count, let check = digits.last else { return false }
        let sum = digits.dropLast().reversed().enumerated()
            .reduce(0) { $0 + $1.element * ($1.offset % 2 == 0 ? 3 : 1) }
        return (10 - sum % 10) % 10 == check
    }
}
