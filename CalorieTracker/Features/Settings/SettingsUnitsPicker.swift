import SwiftUI
import SwiftData

/// Unit-system segmented control (spec §3). Thin wrapper over the shared
/// `PillSegmentedControl` that persists the choice to `UserSettings`.
struct SettingsUnitsPicker: View {
    @Environment(\.modelContext) private var context

    let settings: UserSettings

    var body: some View {
        PillSegmentedControl(
            options: UnitSystem.allCases,
            label: { $0.label },
            selection: Binding(
                get: { settings.unitSystem },
                set: { newValue in
                    settings.unitSystem = newValue
                    try? context.save()
                }
            )
        )
    }
}
