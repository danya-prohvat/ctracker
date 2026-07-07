import SwiftUI
import SwiftData

/// Legacy "Nutrients" destination. The approved prototype merges nutrient
/// tracking into the single Goals & nutrients page, so every existing entry
/// point that pushes this view lands on the same unified screen.
struct NutrientsSettingsView: View {
    init() {}

    var body: some View {
        GoalsView()
    }
}

#Preview {
    NavigationStack {
        NutrientsSettingsView()
    }
    .modelContainer(PreviewData.container)
}
