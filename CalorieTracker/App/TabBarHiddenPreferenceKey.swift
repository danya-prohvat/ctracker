import SwiftUI

/// Pushed subscreens (Goals & nutrients, day details, reminders) cover the
/// floating tab bar in the prototype. They raise this preference so RootView
/// can hide the bar while they are on top.
struct TabBarHiddenPreferenceKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    /// Hides the floating tab bar while this view is on screen.
    func hidesFloatingTabBar(_ hidden: Bool = true) -> some View {
        preference(key: TabBarHiddenPreferenceKey.self, value: hidden)
    }
}
