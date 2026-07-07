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
            Text(verbatim: direction == .decrement ? "−" : "+")
                .font(.system(size: glyphSize))
                .foregroundStyle(glyphColor)
                .frame(width: size, height: size)
                .background(Circle().fill(fill))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(direction == .decrement ? Text("Decrease") : Text("Increase"))
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
