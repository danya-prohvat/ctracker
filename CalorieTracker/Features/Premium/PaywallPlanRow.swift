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
                    HStack(spacing: 8) {
                        titleText
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if plan == .yearly {
                            Text("BEST VALUE")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .badgeFit()
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Theme.accent))
                        }
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
