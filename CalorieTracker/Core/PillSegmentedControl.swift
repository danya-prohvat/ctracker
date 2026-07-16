import SwiftUI

/// Segmented control shared by the settings unit-system picker and the
/// calendar week/month toggle so the two stay visually identical. Wraps the
/// native segmented `Picker` — the same system glass look as the onboarding
/// units toggle (user request 2026-07-16; replaced the hand-drawn
/// prototype-style track with a white pill).
struct PillSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    let label: (Option) -> LocalizedStringKey
    @Binding var selection: Option

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(label(option)).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }
}
