import SwiftUI

/// Trailing "›" disclosure used by the prototype's settings rows.
/// SF chevron flips automatically under RTL layouts.
struct SettingsRowChevron: View {
    var body: some View {
        Image(systemName: "chevron.forward")
            .font(.footnote.weight(.semibold))
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

/// Leading icon tile of a settings row (iOS Settings style, user decision
/// 2026-11-12): 28 pt continuous rounded square in one of the `Theme.tile*`
/// hues with a white glyph — an SF Symbol, or a template SVG from the asset
/// catalog where SF has no honest glyph (the macro food icons). White on a
/// filled tile is the same deliberate exception as white text on accent CTAs
/// — the tile is the colored surface.
struct SettingsRowIcon: View {
    enum Glyph {
        case symbol(String)
        /// Template image set in `Assets.xcassets` (vector SVG, rendered
        /// at a fixed 17 pt — about the visual size of a semibold SF Symbol
        /// at `.subheadline`).
        case asset(String)
    }

    let glyph: Glyph
    let tint: Color

    init(systemName: String, tint: Color) {
        self.init(glyph: .symbol(systemName), tint: tint)
    }

    init(glyph: Glyph, tint: Color) {
        self.glyph = glyph
        self.tint = tint
    }

    var body: some View {
        glyphImage
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(tint, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var glyphImage: some View {
        switch glyph {
        case .symbol(let name):
            Image(systemName: name)
                .font(.subheadline.weight(.semibold))
        case .asset(let name):
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 17, height: 17)
        }
    }
}

/// Standard settings row body: icon tile, title with optional subtitle, an
/// optional trailing value (`On`, the picked language…) and the chevron.
/// Rows with a custom trailing control (menu pickers, switches) compose
/// `SettingsRowIcon` + `settingsIconRowPadding()` themselves.
struct SettingsRowLabel: View {
    let icon: String
    let tint: Color
    let title: LocalizedStringKey
    var subtitle: Text? = nil
    var value: Text? = nil
    var showsChevron = true
    var titleColor: Color = Theme.textPrimary

    var body: some View {
        HStack(spacing: 12) {
            SettingsRowIcon(systemName: icon, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .foregroundStyle(titleColor)
                if let subtitle {
                    subtitle
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            Spacer(minLength: 12)
            if let value {
                value
                    .font(.subheadline)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            if showsChevron {
                SettingsRowChevron()
            }
        }
        .settingsIconRowPadding()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// Standard row insets from the prototype settings cards (13pt / 16pt).
    func settingsRowPadding() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
    }

    /// Insets for rows with a 28 pt icon tile: a little less vertical padding
    /// so the row lands near the native 48 pt instead of growing with the tile.
    func settingsIconRowPadding() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 0) {
            SettingsRowLabel(icon: "globe", tint: Theme.tileSlate, title: "Language", value: Text("System"))
            SettingsRowDivider()
            SettingsRowLabel(
                icon: "bell.badge", tint: Theme.tileCoral, title: "Reminders",
                subtitle: Text(verbatim: "At 14:00 and 20:00, only when needed"), value: Text("On")
            )
            SettingsRowDivider()
            SettingsRowLabel(icon: "trash", tint: Theme.tileRed, title: "Delete all data",
                             showsChevron: false, titleColor: Theme.destructive)
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
        .padding(20)
    }
}
