import SwiftUI

/// Pure-SwiftUI switch drawn to match the native one (51×31 capsule, white
/// knob, tint when on). The system `Toggle` is UISwitch-backed, and on iOS 26
/// it drops quick taps — reproduced 2026-09-27 in a clean test app for
/// VStack, ScrollView and List alike (a 0.2 s press worked, a tap did not), so
/// every switch in the app needed two or three taps. A Button-driven switch
/// reacts to the first tap like every other button here, and gets an
/// invisible margin so the target meets the 44 pt minimum. Installed app-wide
/// in `RootView` via `.toggleStyle(.appSwitch)`; call sites keep `Toggle`.
struct AppSwitchStyle: ToggleStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            SwitchTrack(isOn: configuration.isOn)
                .padding(.horizontal, 6)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressableScale)
        // Give the margin back to layout: the row keeps the native switch's
        // footprint, only the hit area grows.
        .padding(.horizontal, -6)
        .padding(.vertical, -7)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

extension ToggleStyle where Self == AppSwitchStyle {
    static var appSwitch: AppSwitchStyle { AppSwitchStyle() }
}

private struct SwitchTrack: View {
    let isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(Theme.toggleOff))
            .frame(width: 51, height: 31)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .frame(width: 27, height: 27)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .padding(2)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isOn)
    }
}

#Preview {
    struct Demo: View {
        @State private var on = true
        @State private var off = false
        var body: some View {
            VStack(spacing: 20) {
                Toggle("On", isOn: $on).labelsHidden()
                Toggle("Off", isOn: $off).labelsHidden()
                Toggle("Disabled", isOn: $on).labelsHidden().disabled(true)
            }
            .toggleStyle(.appSwitch)
            .tint(Theme.accent)
            .padding()
        }
    }
    return Demo()
}
