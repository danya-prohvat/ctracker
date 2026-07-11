import SwiftUI

/// Prototype-style segmented control: `controlFill` track, radius-12 container,
/// 3pt inset, with the selected option riding a white radius-9 pill. Shared by
/// the settings unit-system picker and the calendar week/month toggle so the
/// two stay visually identical.
struct PillSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    let label: (Option) -> LocalizedStringKey
    @Binding var selection: Option

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                segment(option)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusControl, style: .continuous)
                .fill(Theme.controlFill)
        )
    }

    private func segment(_ option: Option) -> some View {
        let isSelected = selection == option
        return Button {
            guard selection != option else { return }
            withAnimation(.easeOut(duration: 0.15)) {
                selection = option
            }
        } label: {
            Text(label(option))
                .font(.subheadline.weight(.semibold))
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
