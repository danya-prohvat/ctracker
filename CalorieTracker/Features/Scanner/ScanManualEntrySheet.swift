import SwiftUI

/// Manual barcode entry (user decision 2026-09-28): a small sheet over the
/// scanner for torn or glared codes and for denied camera access. The typed
/// code leaves through `onLookup` into the flow's `handleCode` — the very
/// path a camera read takes: own base first, then Open Food Facts, with the
/// free-scan counter and the rewarded ad applying identically. A sheet, not
/// an inline field: the keyboard would squeeze the viewfinder layout.
struct ScanManualEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    let onLookup: (String) -> Void

    @State private var code = ""
    @FocusState private var isFocused: Bool

    private var verdict: BarcodeInput.Verdict { BarcodeInput.verdict(code) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                field
                hint
                ProductFormPrimaryButton(title: "Look up code", action: lookUp)
                    .disabled(verdict != .valid)
                    .opacity(verdict == .valid ? 1 : 0.5)
                    .padding(.top, 6)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .contentColumn()
            .background(AppBackground())
            .navigationTitle("Enter barcode")
            .navigationBarTitleDisplayMode(.inline)
        }
        // No Close button (user decision 2026-09-27): swipe-down closes.
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .task {
            // Focus once the presentation settles — set on appear, the
            // sheet transition drops it.
            try? await Task.sleep(for: .milliseconds(350))
            isFocused = true
        }
    }

    private var field: some View {
        TextField("Barcode", text: $code)
            .keyboardType(.numberPad)
            .font(.title2.weight(.medium))
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .foregroundStyle(Theme.textPrimary)
            .focused($isFocused)
            // Digits only, capped — anything else typed or pasted is dropped.
            .onChange(of: code) { _, value in
                let clean = BarcodeInput.sanitized(value)
                if clean != value { code = clean }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .glassCard(cornerRadius: Theme.cornerRadius)
    }

    private var hint: some View {
        Group {
            switch verdict {
            case .valid, .tooShort:
                Text("Type the digits printed under the barcode")
                    .foregroundStyle(Theme.textSecondary)
            case .badLength, .badCheckDigit:
                Text("That doesn't look like a valid barcode")
                    .foregroundStyle(Theme.warning)
            }
        }
        .font(.footnote)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    /// Hands the code over and closes; the flow runs the lookup from the
    /// sheet's `onDismiss`, so an ad or a hand-off never races the dismissal.
    private func lookUp() {
        guard verdict == .valid else { return }
        onLookup(BarcodeInput.normalizedForLookup(code))
        dismiss()
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ScanManualEntrySheet { _ in }
        }
}
