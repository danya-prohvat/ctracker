import SwiftUI

/// Trailing "›" disclosure used by the prototype's settings rows.
/// SF chevron flips automatically under RTL layouts.
struct SettingsRowChevron: View {
    var body: some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.chevron)
    }
}

/// Hairline separator between rows inside a glass settings card
/// (prototype: 1px rgba(60,60,67,.07), full card width).
struct SettingsRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(height: 1)
    }
}

extension View {
    /// Standard row insets from the prototype settings cards (13pt / 16pt).
    func settingsRowPadding() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
    }
}
