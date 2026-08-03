import Foundation

/// Product-list derivations for the Add food page (spec §5), kept on
/// `[Product]` so the ordering rules live in one place.
extension Array where Element == Product {
    /// "My products" order: latest activity first — `lastLoggedAt` for logged
    /// products, `createdAt` for never-logged ones, so a just-created product
    /// appears at the top instead of below every logged one (user request
    /// 2026-07-21).
    var byRecentActivity: [Product] {
        sorted { ($0.lastLoggedAt ?? $0.createdAt) > ($1.lastLoggedAt ?? $1.createdAt) }
    }

    /// Case-insensitive name filter; a blank query returns everything.
    func matching(_ query: String) -> [Product] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return self }
        return filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    /// Last 8 distinct logged products (spec §5) — relies on the query's
    /// `lastLoggedAt`-descending order (nil last).
    var recentlyLogged: [Product] {
        filter { $0.lastLoggedAt != nil }.prefix(8).map { $0 }
    }
}
