import SwiftUI

/// Pinned bottom action row of the quantity sheet: an optional trash button
/// (edit mode) and the primary CTA, sitting directly on the page background —
/// no separating bar or hairline.
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
                .buttonStyle(.pressableScale)
            }

            Button(action: onCommit) {
                Text(ctaTitle)
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .ctaFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                            .fill(isEnabled ? Theme.accentStrong : Theme.toggleOff)
                            .shadow(color: Theme.accentStrong.opacity(isEnabled ? 0.45 : 0),
                                    radius: 10, y: 6)
                    )
            }
            .buttonStyle(.pressableCard)
            .disabled(!isEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
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
