import SwiftUI
import SwiftData

/// Soft paywall (spec §9): value proposition, compact radio-style plan rows,
/// single "Continue" CTA. Presented as a sheet (swipe-down closes, no close
/// button — user decision 2026-09-27) or, after onboarding, as a full-screen
/// cover that can't be swiped away, so only that caller asks for the X.
///
/// Plan names and prices come from the store via `PurchaseService.quotes()`
/// (RevenueCat when wired), rendered instantly from `PaywallQuotesCache`
/// (warmed at scene activation) — skeletons only appear on a cold cache.
struct PaywallView: View {
    /// True only for the post-onboarding full-screen cover.
    var showsCloseButton = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [UserSettings]

    @State private var selected: PaywallPlan = .yearly
    /// nil = quotes are still loading (rows show skeletons).
    @State private var quotes: [PaywallPlan: PaywallPlanQuote]?
    @State private var isWorking = false
    @State private var closeVisible = false
    @State private var legal: PaywallLegalPage?
    @State private var alert: PurchaseFlowAlert?

    private var currentSettings: UserSettings {
        settingsList.first ?? UserSettings.current(in: context)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                PaywallHeader()
                PaywallFeatureList()
                planList
                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 24)
            .contentColumn()
        }
        .background(AppBackground())
        // Presented as a sheet from several places — the grabber lives here
        // so every call site gets it. Ignored by the onboarding cover.
        .presentationDragIndicator(.visible)
        .overlay(alignment: .topTrailing) {
            if showsCloseButton { closeButton }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.3)) { closeVisible = true }
        }
        .task {
            quotes = PaywallQuotesCache.cached
            quotes = await PaywallQuotesCache.load(settings: currentSettings)
        }
        .adaptiveSheet(item: $legal) { page in
            SafariWebView(url: page.url)
                .ignoresSafeArea()
                .presentationDragIndicator(.visible)
        }
        .purchaseFlowAlert($alert)
    }

    // MARK: - Sections

    /// Close control for the full-screen cover — appears only after a 1.5 s
    /// delay (soft paywall).
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Theme.card))
                .overlay(Circle().stroke(Theme.separator, lineWidth: 1))
        }
        .buttonStyle(.pressableScale)
        .padding(.trailing, 20)
        .padding(.top, 14)
        .opacity(closeVisible ? 1 : 0)
        .disabled(!closeVisible)
        .accessibilityLabel("Close")
    }

    private var planList: some View {
        VStack(spacing: 10) {
            ForEach(PaywallPlan.allCases) { plan in
                PaywallPlanRow(plan: plan,
                               quote: quotes?[plan],
                               isLoadingQuotes: quotes == nil,
                               isSelected: selected == plan) {
                    selected = plan
                }
            }
        }
    }

    /// CTA + legal links, inline at the end of the scroll content (user
    /// decision 2026-07-21) — not a pinned bar, so plan rows never slide
    /// underneath it while scrolling.
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
    }

    private var ctaButton: some View {
        Button {
            buy()
        } label: {
            ZStack {
                Text("Continue")
                    .font(.headline)
                    .ctaFit()
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
        .buttonStyle(.pressableCard)
        .disabled(isWorking)
    }

    // MARK: - Actions

    private func buy() {
        run(phase: .purchase) { service in
            try await service.purchase(selected)
        }
    }

    private func restore() {
        run(phase: .restore) { service in
            try await service.restore()
            // Restore "succeeded" but found nothing — say so instead of
            // leaving the user tapping a button that does nothing.
            guard currentSettings.isPremium else { throw PurchaseFlowError.nothingToRestore }
        }
    }

    /// Shared plumbing for both store actions: in-flight guard + spinner, save
    /// and dismiss on success, alert on failure (user cancellation stays silent).
    private func run(phase: PurchaseFlowPhase,
                     _ action: @escaping (PurchaseService) async throws -> Void) {
        guard !isWorking else { return }
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                try await action(PurchaseServices.make(settings: currentSettings))
                try? context.save()
                dismiss()
            } catch {
                guard !PurchaseFlowError.isUserCancellation(error) else { return }
                alert = PurchaseFlowAlert(error, phase: phase)
            }
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

#Preview("RTL ar") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PaywallView()
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
        }
        .modelContainer(PreviewData.container)
}
