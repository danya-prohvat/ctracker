import SwiftUI

/// Chrome for a pushed detail screen that hides the system nav bar: a centered
/// inline title with a leading green back button (chevron + label), matching the
/// iOS pushed-screen look. Shared by the day detail and the Add-food page.
///
/// Pass `Text` (not raw strings) so each caller controls localization: a literal
/// like `Text("Add food")` localizes, a formatted date like `Text(dayLabel)`
/// stays verbatim.
struct DetailNavHeader: View {
    let backLabel: Text
    let title: Text
    let onBack: () -> Void

    var body: some View {
        ZStack {
            title
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.backward")
                            .font(.body.weight(.semibold))
                        backLabel
                            .font(.body)
                    }
                    .foregroundStyle(Theme.accentLabel)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack {
            DetailNavHeader(
                backLabel: Text(verbatim: "July"),
                title: Text(verbatim: "9 July"),
                onBack: {}
            )
            DetailNavHeader(
                backLabel: Text(verbatim: "9 July"),
                title: Text("Add food"),
                onBack: {}
            )
            Spacer()
        }
    }
}
