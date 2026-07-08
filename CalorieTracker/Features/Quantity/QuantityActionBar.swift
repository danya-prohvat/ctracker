import SwiftUI

/// Pinned bottom bar of the quantity sheet: hairline + thin material,
/// an optional trash button (edit mode) and the primary CTA.
struct QuantityActionBar: View {
    let ctaTitle: LocalizedStringKey
    let isEnabled: Bool
    let onDelete: (() -> Void)?
    let onCommit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Theme.destructive)
                        .frame(width: 54, height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                                .fill(Theme.destructiveSoft)
                        )
                }
                .buttonStyle(.plain)
            }

            Button(action: onCommit) {
                Text(ctaTitle)
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                            .fill(isEnabled ? Theme.accentStrong : Theme.toggleOff)
                            .shadow(color: Theme.accentStrong.opacity(isEnabled ? 0.45 : 0),
                                    radius: 10, y: 6)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            Rectangle()
                .fill(.thinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
        }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppBackground()
        QuantityActionBar(
            ctaTitle: "Save changes",
            isEnabled: true,
            onDelete: {},
            onCommit: {}
        )
    }
}
