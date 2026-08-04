import SwiftUI

/// Compact selectable plan row (radio style). Prices come exclusively from the
/// store: `quote == nil` + `isLoadingQuotes` → skeleton, `quote == nil` after
/// loading → "—" (plan unavailable), otherwise the real localized price.
struct PaywallPlanRow: View {
    let plan: PaywallPlan
    let quote: PaywallPlanQuote?
    let isLoadingQuotes: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)

                VStack(alignment: .leading, spacing: 3) {
                    if plan == .yearly {
                        // SE-width screens: title + pill + price don't fit on
                        // one line, and the fixed pill would squeeze the title
                        // into letter-per-line wrapping — drop the pill under
                        // the title instead.
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 8) {
                                titleLabel
                                bestValueBadge
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                titleLabel
                                bestValueBadge
                            }
                        }
                    } else {
                        titleLabel
                    }
                    if plan == .lifetime {
                        Text("One-time purchase")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    price
                        .font(.stat(.subheadline, .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    priceDetail
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(isSelected ? Theme.accent : Theme.separator,
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    /// Store product title when the store provided one, static name otherwise.
    private var titleText: Text {
        if let title = quote?.title {
            Text(verbatim: title)
        } else {
            Text(plan.displayName)
        }
    }

    private var titleLabel: some View {
        titleText
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.textPrimary)
    }

    private var bestValueBadge: some View {
        Text("BEST VALUE")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .badgeFit()
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(Theme.accent))
    }

    @ViewBuilder private var price: some View {
        if let quote {
            priceText(for: quote)
        } else if isLoadingQuotes {
            // Dummy width for the skeleton bar; never visible under redaction.
            Text(verbatim: "0.00 / xxxx")
                .redacted(reason: .placeholder)
        } else {
            Text(verbatim: "—")
        }
    }

    private func priceText(for quote: PaywallPlanQuote) -> Text {
        switch plan {
        case .weekly: Text("\(quote.price) / week")
        case .monthly: Text("\(quote.price) / month")
        case .yearly: Text("\(quote.price) / year")
        case .lifetime: Text(verbatim: quote.price)
        }
    }

    @ViewBuilder private var priceDetail: some View {
        if plan == .lifetime {
            Text("Pay once, keep forever")
        } else if let perMonth = quote?.pricePerMonth {
            Text("\(perMonth) / month")
        }
    }
}
