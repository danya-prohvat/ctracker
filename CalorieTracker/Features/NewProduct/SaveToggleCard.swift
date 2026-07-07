import SwiftUI

/// "Save to My products" glass card with the accent toggle. Off = the entry is
/// logged once without persisting a Product (existing semantics).
struct SaveToggleCard: View {
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Save to My products")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Off = log once without saving")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            Toggle("Save to My products", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: Theme.cornerRadius)
    }
}

#Preview {
    ZStack {
        AppBackground()
        SaveToggleCard(isOn: .constant(true))
            .padding(20)
    }
}
