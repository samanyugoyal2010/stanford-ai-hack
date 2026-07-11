import AppKit
import Foundation

/// Shows / hides the main StudyFlow SwiftUI window during listening mode.
enum MainWindowController {
    /// Hide the primary StudyFlow window without quitting the app.
    @MainActor
    static func hideMainWindow() {
        NSApp.windows
            .filter { $0.isVisible && isMainStudyFlowWindow($0) }
            .forEach { $0.orderOut(nil) }
    }

    /// Bring StudyFlow to the front and show its main window.
    @MainActor
    static func showAndActivateMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: isMainStudyFlowWindow) {
            window.makeKeyAndOrderFront(nil)
            return
        }
        // Fallback: show any app window.
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    private static func isMainStudyFlowWindow(_ window: NSWindow) -> Bool {
        // Skip status-item / menu-bar panels and panels without a normal title.
        guard window.level == .normal || window.level == .floating else { return false }
        guard window.styleMask.contains(.titled) else { return false }
        return true
    }
}
