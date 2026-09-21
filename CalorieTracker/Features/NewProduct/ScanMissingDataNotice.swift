import SwiftUI

/// What a scanned database card (often a half-filled Open Food Facts entry)
/// failed to provide.
enum ScanMissingData {
    case name, nutrition, both

    init?(nameMissing: Bool, nutritionMissing: Bool) {
        switch (nameMissing, nutritionMissing) {
        case (true, true): self = .both
        case (true, false): self = .name
        case (false, true): self = .nutrition
        case (false, false): return nil
        }
    }
}

/// Amber info card shown when a scanned barcode matched a database product
/// whose card is incomplete: explains why fields below are empty and asks the
/// user to copy them from the package.
struct ScanMissingDataNotice: View {
    let missing: ScanMissingData

    private var title: LocalizedStringKey {
        switch missing {
        case .name: "No product name"
        case .nutrition: "No nutrition data yet"
        case .both: "No product data yet"
        }
    }

    private var message: LocalizedStringKey {
        switch missing {
        case .name:
            "The product was found, but its name is missing. Enter it from the package."
        case .nutrition:
            "The product was found, but its nutrition values are missing. Enter them from the label."
        case .both:
            "The barcode was found, but the name and nutrition values are missing. Enter them from the package."
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.body)
                .foregroundStyle(Theme.warning)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(message)
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
        VStack(spacing: 14) {
            ScanMissingDataNotice(missing: .name)
            ScanMissingDataNotice(missing: .nutrition)
            ScanMissingDataNotice(missing: .both)
        }
        .padding(20)
    }
}
