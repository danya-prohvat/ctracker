import SwiftUI
import SwiftData

/// Purchase plans offered on the paywall (spec §9). Weekly / monthly / yearly
/// are auto-renewable subscriptions; lifetime is a one-time non-consumable.
/// No free trial anywhere.
enum PaywallPlan: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly
    case lifetime

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    var pricing: PaywallPricing { .placeholder(for: self) }
}

/// Hardcoded placeholder prices shown until billing is wired.
/// TODO(RevenueCat): replace with localized `StoreProduct` price strings once
/// the SDK is active (see RevenueCatPurchaseService.swift).
struct PaywallPricing {
    /// Main trailing price line, e.g. "$29.99 / year".
    var price: String
    /// Small trailing line under the price (per-month equivalent etc.).
    var priceDetail: LocalizedStringKey?
    /// Small leading line under the plan name.
    var caption: LocalizedStringKey?

    static func placeholder(for plan: PaywallPlan) -> PaywallPricing {
        switch plan {
        case .weekly:
            return PaywallPricing(price: "$1.99 / week", priceDetail: nil, caption: nil)
        case .monthly:
            return PaywallPricing(price: "$4.99 / month", priceDetail: nil, caption: nil)
        case .yearly:
            return PaywallPricing(price: "$29.99 / year",
                                  priceDetail: "$2.49 / month",
                                  caption: nil)
        case .lifetime:
            return PaywallPricing(price: "$49.99",
                                  priceDetail: "Pay once, keep forever",
                                  caption: "One-time purchase")
        }
    }
}

/// Soft paywall (spec §9): closable (after a short delay), value proposition,
/// compact radio-style plan rows, single "Continue" CTA. Present in a `.sheet`.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [UserSettings]

    @State private var selected: PaywallPlan = .yearly
    @State private var isWorking = false
    @State private var closeVisible = false
    @State private var legal: PaywallLegalPage?
    @State private var errorMessage: String?

    init() {}

    private var currentSettings: UserSettings {
        settingsList.first ?? UserSettings.current(in: context)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header
                featureList
                planList
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 12)
        }
        .background(Theme.background)
        .safeAreaInset(edge: .bottom) { footer }
        .overlay(alignment: .topLeading) { closeButton }
        .task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.3)) { closeVisible = true }
        }
        .sheet(item: $legal) { page in
            SafariWebView(url: page.url)
                .ignoresSafeArea()
        }
        .alert(
            "Purchase failed",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Sections

    /// Close control — appears only after a 1.5 s delay (soft paywall).
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Theme.card))
                .overlay(Circle().stroke(Theme.separator, lineWidth: 1))
        }
        .padding(.leading, 20)
        .padding(.top, 14)
        .opacity(closeVisible ? 1 : 0)
        .disabled(!closeVisible)
        .accessibilityLabel("Close")
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)
                .frame(width: 74, height: 74)
                .background(Circle().fill(Theme.accentSoft))
            Text("Unlock the full nutrition picture")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("Go beyond calories and macros with Premium.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 18) {
            PaywallFeatureRow(icon: "pills.fill",
                              title: "All 37 vitamins & minerals",
                              subtitle: "The complete micronutrient picture, every day.")
            PaywallFeatureRow(icon: "barcode.viewfinder",
                              title: "Unlimited barcode scanner",
                              subtitle: "Scan any product, no limits.")
            PaywallFeatureRow(icon: "icloud.fill",
                              title: "iCloud sync",
                              subtitle: "Your diary on all your devices.")
            PaywallFeatureRow(icon: "calendar",
                              title: "Full calendar history",
                              subtitle: "Look back further than 30 days.")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.card)
                .shadow(color: Theme.cardShadow, radius: 8, y: 2)
        )
    }

    private var planList: some View {
        VStack(spacing: 10) {
            ForEach(PaywallPlan.allCases) { plan in
                PaywallPlanRow(plan: plan, isSelected: selected == plan) {
                    selected = plan
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            ctaButton
            HStack(spacing: 18) {
                Button("Restore purchases") { restore() }
                Button("Terms of Use") { legal = .terms }
                Button("Privacy Policy") { legal = .privacy }
            }
            .font(.footnote)
            .foregroundStyle(Theme.textSecondary)
            .disabled(isWorking)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Theme.background)
    }

    private var ctaButton: some View {
        Button {
            buy()
        } label: {
            ZStack {
                Text("Continue")
                    .font(.headline)
                    .opacity(isWorking ? 0 : 1)
                if isWorking {
                    ProgressView()
                        .tint(.white)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(Theme.accent)
            )
        }
        .disabled(isWorking)
    }

    // MARK: - Actions

    private func buy() {
        guard !isWorking else { return }
        isWorking = true
        Task {
            defer { isWorking = false }
            // TODO(RevenueCat): swap in RevenueCatPurchaseService when billing
            // is wired (same initializer).
            let service = StubPurchaseService(settings: currentSettings)
            do {
                try await service.purchase(selected)
                try? context.save()
                dismiss()
            } catch is CancellationError {
                // User backed out of the store sheet — stay on the paywall.
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func restore() {
        guard !isWorking else { return }
        isWorking = true
        Task {
            defer { isWorking = false }
            let service = StubPurchaseService(settings: currentSettings)
            do {
                try await service.restore()
                try? context.save()
                if currentSettings.isPremium { dismiss() }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Rows

private struct PaywallFeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.accentSoft))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }
}

/// Compact selectable plan row (radio style).
private struct PaywallPlanRow: View {
    let plan: PaywallPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(plan.displayName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if plan == .yearly {
                            Text("BEST VALUE")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Theme.accent))
                        }
                    }
                    if let caption = plan.pricing.caption {
                        Text(caption)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(verbatim: plan.pricing.price)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if let detail = plan.pricing.priceDetail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
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
}

// MARK: - Legal sheets

private enum PaywallLegalPage: String, Identifiable {
    case terms
    case privacy

    var id: String { rawValue }

    var url: URL {
        switch self {
        case .terms: return AppLinks.termsURL
        case .privacy: return AppLinks.privacyURL
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PaywallView()
        }
        .modelContainer(PreviewData.container)
}
