import Foundation

/// UPC-A ↔ EAN-13 bridging (spec §7): the camera reports a UPC-A as an
/// EAN-13 with a leading zero, while Open Food Facts and the user's own base
/// may hold the product under either form. Lookups therefore try every
/// candidate, as-scanned first.
enum BarcodeNormalizer {
    static func candidates(for code: String) -> [String] {
        var candidates = [code]
        if code.count == 13, code.hasPrefix("0"),
           code.allSatisfy({ $0.isASCII && $0.isNumber }) {
            candidates.append(String(code.dropFirst()))
        }
        return candidates
    }
}
