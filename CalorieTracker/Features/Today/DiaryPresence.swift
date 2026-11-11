import SwiftData

/// "Is there anything in the database at all?" probes for the Today empty
/// state: its scan / add CTAs are for a brand-new user only (user decision
/// 2026-11-11); once a single product or diary entry exists the card goes
/// back to the plain "+" hint. One-row fetches, reactive through `@Query`.
enum DiaryPresence {
    static var anyProduct: FetchDescriptor<Product> {
        var descriptor = FetchDescriptor<Product>()
        descriptor.fetchLimit = 1
        return descriptor
    }

    static var anyEntry: FetchDescriptor<DiaryEntry> {
        var descriptor = FetchDescriptor<DiaryEntry>()
        descriptor.fetchLimit = 1
        return descriptor
    }
}
