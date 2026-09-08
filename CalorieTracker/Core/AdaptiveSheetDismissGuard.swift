import SwiftUI

/// Bridges a modal's "don't lose my edits" state to whichever chrome hosts it.
/// On iPhone the content lives in a system sheet, so the guard is exactly
/// `interactiveDismissDisabled`; on iPad `PadSheetChrome` (custom bottom sheet
/// in a full-screen cover) dismisses programmatically, which bypasses that
/// modifier — so the chrome consults this object before closing and, when
/// guarded, calls `onAttempt` (the content's discard alert) instead.
@Observable
final class AdaptiveSheetDismissGuard {
    var isGuarded = false
    var onAttempt: () -> Void = {}
}

private struct AdaptiveSheetDismissGuardKey: EnvironmentKey {
    static let defaultValue: AdaptiveSheetDismissGuard? = nil
}

extension EnvironmentValues {
    /// Injected by `PadSheetChrome`; nil on iPhone (system sheet handles it).
    var adaptiveSheetDismissGuard: AdaptiveSheetDismissGuard? {
        get { self[AdaptiveSheetDismissGuardKey.self] }
        set { self[AdaptiveSheetDismissGuardKey.self] = newValue }
    }
}

extension View {
    /// Adaptive-sheet counterpart of `interactiveDismissDisabled`: while
    /// `isGuarded`, iPhone's swipe-down and the pad chrome's grabber flick /
    /// backdrop tap don't dismiss — the pad chrome calls `onAttempt` instead
    /// (wire it to the content's own discard-confirmation UI).
    func adaptiveSheetDismissGuard(_ isGuarded: Bool,
                                   onAttempt: @escaping () -> Void) -> some View {
        modifier(AdaptiveSheetDismissGuardModifier(isGuarded: isGuarded, onAttempt: onAttempt))
    }
}

private struct AdaptiveSheetDismissGuardModifier: ViewModifier {
    @Environment(\.adaptiveSheetDismissGuard) private var dismissGuard
    let isGuarded: Bool
    let onAttempt: () -> Void

    func body(content: Content) -> some View {
        content
            .interactiveDismissDisabled(isGuarded)   // iPhone system-sheet path
            .onAppear(perform: sync)
            .onChange(of: isGuarded) { sync() }
            .onDisappear {
                // The guarded screen may be a pushed step inside the sheet
                // (NewProductForm in the Add-food stack) — popping it must
                // release the chrome's guard.
                dismissGuard?.isGuarded = false
                dismissGuard?.onAttempt = {}
            }
    }

    private func sync() {
        dismissGuard?.isGuarded = isGuarded
        dismissGuard?.onAttempt = onAttempt
    }
}
