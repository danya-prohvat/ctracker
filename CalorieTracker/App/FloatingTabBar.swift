import SwiftUI

/// Floating glass pill tab bar from the prototype with hand-drawn icons:
/// list lines (Today), calendar outline (Calendar), circled dot (Settings).
struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            tab(.today, label: "Today") { listIcon(color: color(for: .today)) }
            tab(.calendar, label: "Calendar") { calendarIcon(color: color(for: .calendar)) }
            tab(.settings, label: "Settings") { settingsIcon(color: color(for: .settings)) }
        }
        .frame(height: 64)
        .background {
            let shape = Capsule()
            shape
                .fill(.ultraThinMaterial)
                .overlay(shape.fill(Color.white.opacity(0.38)))
                .overlay(shape.strokeBorder(Color.white.opacity(0.7), lineWidth: 0.5))
                .shadow(color: Color(hex: 0x1C263A).opacity(0.3), radius: 16, y: 8)
        }
    }

    private func color(for tab: AppTab) -> Color {
        selection == tab ? Theme.accent : Theme.textSecondary
    }

    private func tab<Icon: View>(
        _ tab: AppTab, label: LocalizedStringKey, @ViewBuilder icon: () -> Icon
    ) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 5) {
                icon()
                Text(label)
                    .font(.system(size: 10, weight: selection == tab ? .semibold : .medium))
                    .foregroundStyle(selection == tab ? Theme.accentLabel : Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .opacity(selection == tab ? 1 : 0.55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func listIcon(color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2.5) {
            Capsule().fill(color).frame(width: 22, height: 2.5)
            Capsule().fill(color).frame(width: 22, height: 2.5)
            Capsule().fill(color).frame(width: 13, height: 2.5)
        }
        .frame(height: 20)
    }

    private func calendarIcon(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .strokeBorder(color, lineWidth: 2)
            .frame(width: 20, height: 20)
            .overlay(alignment: .top) {
                HStack {
                    RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 3, height: 4)
                    Spacer()
                    RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 3, height: 4)
                }
                .padding(.horizontal, 3)
                .offset(y: -3)
            }
    }

    private func settingsIcon(color: Color) -> some View {
        Circle()
            .strokeBorder(color, lineWidth: 2)
            .frame(width: 20, height: 20)
            .overlay(Circle().fill(color).frame(width: 6, height: 6))
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppBackground()
        FloatingTabBar(selection: .constant(.today))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }
}
