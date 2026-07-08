import SwiftUI

/// Round −/+ stepper button from the prototype: gray circle for "−",
/// soft-green circle for "+". Used at 44/30/24 pt across the goals page.
struct GoalsStepperCircle: View {
    enum Direction {
        case decrement, increment
    }

    let direction: Direction
    let size: CGFloat
    let glyphSize: CGFloat
    let action: () -> Void

    init(
        _ direction: Direction,
        size: CGFloat,
        glyphSize: CGFloat,
        action: @escaping () -> Void
    ) {
        self.direction = direction
        self.size = size
        self.glyphSize = glyphSize
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: direction == .decrement ? "minus" : "plus")
                .font(glyphFont)
                .foregroundStyle(glyphColor)
                .frame(width: size, height: size)
                .background(Circle().fill(fill))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(direction == .decrement ? Text("Decrease") : Text("Increase"))
    }

    /// Dynamic Type equivalent of the prototype's fixed glyph sizes (26/20/16).
    private var glyphFont: Font {
        switch glyphSize {
        case ..<18: return .callout
        case ..<24: return .title3
        default: return .title
        }
    }

    private var fill: Color {
        direction == .decrement ? Theme.stepperFill : Theme.accentSoftAlt
    }

    private var glyphColor: Color {
        direction == .decrement ? Color(hex: 0x6B6B70) : Theme.accentIcon
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack(spacing: 16) {
            GoalsStepperCircle(.decrement, size: 44, glyphSize: 26) {}
            GoalsStepperCircle(.increment, size: 44, glyphSize: 26) {}
            GoalsStepperCircle(.decrement, size: 30, glyphSize: 20) {}
            GoalsStepperCircle(.increment, size: 24, glyphSize: 16) {}
        }
    }
}
