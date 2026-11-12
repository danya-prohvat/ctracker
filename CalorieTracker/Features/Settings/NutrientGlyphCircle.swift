import SwiftUI

/// Leading badge of a nutrient row (user decision 2026-11-12, "soft circle"
/// picked over the filled Settings tile so nutrients read lighter than the
/// macro rows and the Settings list): a 28 pt circle filled with the group
/// hue at low alpha, the per-nutrient glyph in the full hue on top, and an
/// optional lock badge while the nutrient is premium-locked.
struct NutrientGlyphCircle: View {
    let def: NutrientDef
    var locked = false

    private var tint: Color { def.group.tint }

    var body: some View {
        glyph
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: 28, height: 28)
            .background(tint.opacity(0.16), in: Circle())
            .overlay(alignment: .bottomTrailing) {
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.caption2.weight(.bold))
                        .imageScale(.small)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 15, height: 15)
                        .background(Theme.card, in: Circle())
                        .offset(x: 4, y: 4)
                }
            }
            .accessibilityHidden(true)
    }

    // SF Rounded like the stat numbers; the circle is a fixed 28 pt, so the
    // text styles are picked to fit it (two letters one step smaller).
    @ViewBuilder
    private var glyph: some View {
        switch def.glyph {
        case .text(let main, let sub):
            let mainFont = Font.stat(main.count > 1 ? .footnote : .subheadline)
            if let sub {
                (Text(main).font(mainFont)
                    + Text(sub).font(.stat(.caption2, .heavy)).baselineOffset(-3))
                    .offset(y: -1)
            } else {
                Text(main).font(mainFont)
            }
        case .asset(let name):
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 17, height: 17)
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 12) {
            ForEach(NutrientCatalog.all, id: \.id) { def in
                HStack(spacing: 12) {
                    NutrientGlyphCircle(def: def, locked: def.id == "vitaminB12")
                    Text(def.nameKey)
                    Spacer()
                }
            }
        }
        .padding(20)
    }
}

#Preview("Dark") {
    ZStack {
        AppBackground()
        VStack(spacing: 12) {
            ForEach(NutrientCatalog.all.prefix(12), id: \.id) { def in
                HStack(spacing: 12) {
                    NutrientGlyphCircle(def: def)
                    Text(def.nameKey)
                    Spacer()
                }
            }
        }
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
