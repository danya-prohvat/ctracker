import Foundation

/// Height/weight conversions between the metric truth (cm / kg) and imperial
/// input (inches / lbs). Used only at the input/display boundary (spec §3):
/// the onboarding pickers and the goals calculator convert on read/write,
/// while storage and all calorie math stay metric.
enum BodyUnits {
    static let cmPerInch = 2.54
    static let lbsPerKg = 2.20462
    static let inchesPerFoot = 12.0

    static func cm(fromInches inches: Double) -> Double { inches * cmPerInch }
    static func inches(fromCm cm: Double) -> Double { cm / cmPerInch }
    static func kg(fromLbs lbs: Double) -> Double { lbs / lbsPerKg }
    static func lbs(fromKg kg: Double) -> Double { kg * lbsPerKg }
}
