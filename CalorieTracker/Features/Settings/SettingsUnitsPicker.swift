import SwiftUI
import SwiftData

/// Prototype-style segmented control for the unit system: controlFill track,
/// radius 12, 3pt inset, selected option on a white radius-9 pill.
struct SettingsUnitsPicker: View {
    @Environment(\.modelContext) private var context

    let settings: UserSettings

    var body: some View {
        HStack(spacing: 0) {
            ForEach(UnitSystem.allCases) { system in
                segment(system)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusControl, style: .continuous)
                .fill(Theme.controlFill)
        )
    }

    private func segment(_ system: UnitSystem) -> some View {
        let isSelected = settings.unitSystem == system
        return Button {
            guard settings.unitSystem != system else { return }
            withAnimation(.easeOut(duration: 0.15)) {
                settings.unitSystem = system
            }
            try? context.save()
        } label: {
            Text(system.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
