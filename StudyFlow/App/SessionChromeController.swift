import Foundation
import Observation

/// Drives listening-mode chrome: menu-bar icon visibility + main window hide/show.
@Observable
@MainActor
final class SessionChromeController {
    /// When true, the listening `MenuBarExtra` is inserted in the system menu bar.
    var isListeningChromeActive = false

    /// Enter listening chrome after a successful Start (hide main window, show menu-bar icon).
    func enterListeningMode() {
        isListeningChromeActive = true
        MainWindowController.hideMainWindow()
    }

    /// Leave listening chrome after Stop (remove icon, restore main window).
    func exitListeningMode() {
        isListeningChromeActive = false
        MainWindowController.showAndActivateMainWindow()
    }

    /// User clicked the menu-bar icon / chose Open — bring StudyFlow forward.
    func openMainWindow() {
        MainWindowController.showAndActivateMainWindow()
    }

    /// Shared Stop path for Dashboard and the menu-bar menu.
    func stopListeningSession(
        voiceAgent: VoiceAgentCoordinator,
        observation: ObservationSessionCoordinator
    ) async {
        await voiceAgent.stop()
        _ = try? await observation.stopSession(extractProfile: false)
        exitListeningMode()
    }
}
