import SwiftUI

/// The one back-button look for the whole app: a semibold `chevron.backward`
/// and a "Back" label (user decision 2026-09-17 — every back control reads
/// "Back", never the parent screen's name). Color comes from the surrounding
/// tint/foreground so the same label works on the green nav bars and on the
/// dark scanner header. Every back button must use this, not its own HStack.
struct BackButtonLabel: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "chevron.backward")
                .font(.body.weight(.semibold))
            Text("Back")
                .font(.body)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        BackButtonLabel().foregroundStyle(Theme.accentLabel)
        BackButtonLabel().foregroundStyle(.white).padding().background(Theme.scanBackground)
    }
}
