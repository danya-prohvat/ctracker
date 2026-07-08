import SwiftUI

/// Per-state content shown under (or instead of) the viewfinder in the dark
/// scan flow: hints, spinner, not-found / denied / offline messages.
struct ScanStatusPanel: View {
    let phase: ScanFlowPhase

    var body: some View {
        switch phase {
        case .scanning:
            hint
        case .searching(let code):
            searching(code: code)
        case .found:
            found
        case .notFound(let code):
            notFound(code: code)
        case .denied:
            denied
        case .offline:
            offline
        case .requestingPermission, .handedOff:
            EmptyView()
        }
    }

    // MARK: - States

    private var hint: some View {
        VStack(spacing: 4) {
            Text("Point at a barcode")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
            Text("Align the code inside the frame")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
        }
        .multilineTextAlignment(.center)
    }

    private func searching(code: String) -> some View {
        VStack(spacing: 14) {
            ScanSpinner()
            VStack(spacing: 4) {
                Text("Looking up product…")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Barcode \(code)")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .multilineTextAlignment(.center)
    }

    private var found: some View {
        VStack(spacing: 16) {
            statusCircle {
                Image(systemName: "checkmark")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.scanLine)
            }
            Text("Product found")
                .font(.title3.bold())
                .foregroundStyle(.white)
        }
    }

    private func notFound(code: String) -> some View {
        VStack(spacing: 16) {
            statusCircle {
                Text(verbatim: "?")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.7))
            }
            message(
                title: "Product not found",
                body: "This barcode isn't in our database yet. You can add it manually.",
                maxWidth: 240
            )
            codeChip(code)
        }
    }

    private var denied: some View {
        VStack(spacing: 16) {
            statusCircle {
                Image(systemName: "camera")
                    .font(.title.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 1.25)
                    .fill(Color(hex: 0xFF6B60))
                    .frame(width: 78, height: 2.5)
                    .rotationEffect(.degrees(-45))
            }
            message(
                title: "Camera access is off",
                body: "Allow camera access to scan barcodes, or add the product manually.",
                maxWidth: 250
            )
        }
    }

    private var offline: some View {
        VStack(spacing: 16) {
            statusCircle {
                Image(systemName: "wifi.slash")
                    .font(.title.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            message(
                title: "No connection",
                body: "You're offline. Internet is needed only to look up scanned barcodes.",
                maxWidth: 250
            )
        }
    }

    // MARK: - Pieces

    private func message(
        title: LocalizedStringKey, body: LocalizedStringKey, maxWidth: CGFloat
    ) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
                .lineSpacing(3)
                .frame(maxWidth: maxWidth)
        }
        .multilineTextAlignment(.center)
    }

    private func statusCircle(@ViewBuilder content: () -> some View) -> some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 72, height: 72)
            content()
        }
    }

    private func codeChip(_ code: String) -> some View {
        HStack(spacing: 8) {
            ScanBarcodeGlyph(barWidths: [2, 3, 1, 3, 2, 1], spacing: 2)
                .frame(height: 16)
            Text(verbatim: code)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Theme.scanBackground.ignoresSafeArea()
        VStack(spacing: 40) {
            ScanStatusPanel(phase: .searching("4820000123456"))
            ScanStatusPanel(phase: .notFound("4820000123456"))
            ScanStatusPanel(phase: .denied)
        }
    }
}
