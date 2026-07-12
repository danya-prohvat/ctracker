import SwiftUI

/// Amber info card shown when a scanned barcode matched a database product
/// whose card has no nutrition values (name only, like many half-filled
/// Open Food Facts entries): explains why the fields below are empty and
/// asks the user to copy them from the label.
struct MissingNutritionNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.body)
                .foregroundStyle(Theme.warning)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("No nutrition data yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("The product was found, but its nutrition values are missing. Enter them from the label.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusControl, style: .continuous)
                .fill(Theme.warning.opacity(0.12))
        )
    }
}

#Preview {
    ZStack {
        AppBackground()
        MissingNutritionNotice()
            .padding(20)
    }
}
