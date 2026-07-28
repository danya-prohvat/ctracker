import SwiftUI
import SwiftData

/// Soft paywall (spec §9): closable (after a short delay), value proposition,
/// compact radio-style plan rows, single "Continue" CTA. Present in a `.sheet`.
///
/// Plan names and prices come from the store via `PurchaseService.quotes()`
/// (RevenueCat when wired); placeholders are shown until they arrive.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [UserSettings]

    @State private var selected: PaywallPlan = .yearly
    /// nil = quotes are still loading (rows show skeletons).
    @State private var quotes: [PaywallPlan: PaywallPlanQuote]?
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
                PaywallHeader()
                PaywallFeatureList()
                planList
                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 24)
        }
        .background(AppBackground())
        // Presented as a sheet from several places — the grabber lives here
        // so every call site gets it. Ignored by the onboarding cover.
        .presentationDragIndicator(.visible)
        .overlay(alignment: .topTrailing) { closeButton }
        .task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.3)) { closeVisible = true }
        }
        .task {
            quotes = await PurchaseServices.make(settings: currentSettings).quotes()
        }
        .sheet(item: $legal) { page in
            SafariWebView(url: page.url)
                .ignoresSafeArea()
                .presentationDragIndicator(.visible)
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
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Theme.card))
                .overlay(Circle().stroke(Theme.separator, lineWidth: 1))
        }
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
            let service = PurchaseServices.make(settings: currentSettings)
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
            let service = PurchaseServices.make(settings: currentSettings)
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

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PaywallView()
        }
        .modelContainer(PreviewData.container)
}
