import SwiftUI
import UIKit

/// State-dependent bottom action stack of the dark scan flow: a 54pt green
/// primary button plus a 50pt translucent secondary one, per the prototype.
struct ScanActionBar: View {
    let phase: ScanFlowPhase
    @Binding var manualCode: String
    let onManualLookup: (String) -> Void
    let onCreateManually: (String) -> Void
    let onScanAgain: () -> Void
    let onRetry: (String) -> Void

    var body: some View {
        switch phase {
        case .scanning:
            #if targetEnvironment(simulator)
            // The simulator has no camera — allow typing a barcode by hand.
            manualLookupBar
            #else
            EmptyView()
            #endif
        case .notFound(let code):
            VStack(spacing: 10) {
                primaryButton("Create manually") { onCreateManually(code) }
                secondaryButton("Scan again", action: onScanAgain)
            }
        case .denied:
            VStack(spacing: 10) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link(destination: url) { primaryLabel("Open Settings") }
                }
                secondaryButton("Add manually instead") { onCreateManually("") }
            }
        case .offline(let code):
            VStack(spacing: 10) {
                primaryButton("Retry") { onRetry(code) }
                secondaryButton("Scan again", action: onScanAgain)
            }
        case .searching, .found, .requestingPermission, .handedOff:
            EmptyView()
        }
    }

    // MARK: - Buttons

    private func primaryButton(
        _ title: LocalizedStringKey, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) { primaryLabel(title) }
    }

    private func primaryLabel(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.body.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.accentStrong)
            )
            .shadow(color: Theme.accentStrong.opacity(0.5), radius: 10, x: 0, y: 8)
    }

    private func secondaryButton(
        _ title: LocalizedStringKey, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.1))
                )
        }
    }

    // MARK: - Simulator manual entry

    #if targetEnvironment(simulator)
    private var manualLookupBar: some View {
        VStack(spacing: 10) {
            TextField("Barcode", text: $manualCode)
                .font(.subheadline)
                .foregroundStyle(.white)
                .tint(Theme.scanLine)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                )
            Button {
                onManualLookup(manualCode)
            } label: {
                Text("Look up code")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .disabled(manualCode.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
    #endif
}

#Preview {
    ZStack {
        Theme.scanBackground.ignoresSafeArea()
        ScanActionBar(
            phase: .notFound("4820000123456"),
            manualCode: .constant(""),
            onManualLookup: { _ in },
            onCreateManually: { _ in },
            onScanAgain: {},
            onRetry: { _ in }
        )
        .padding(.horizontal, 20)
    }
}
