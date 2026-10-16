import SwiftUI
import SwiftData

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PaywallView()
        }
        .modelContainer(PreviewData.container)
}

#Preview("RTL ar") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PaywallView()
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
        }
        .modelContainer(PreviewData.container)
}
