import SwiftUI

/// StudyFlow application entry point (SwiftUI app lifecycle).
///
/// Owns the dependency container for the process lifetime. While a voice session
/// runs, a tiny menu-bar icon replaces the main window until the user clicks it.
@main
struct StudyFlowApp: App {
    @State private var container = AppDependencyContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(container)
                .frame(minWidth: 720, minHeight: 480)
        }
        .defaultSize(width: 900, height: 640)

        MenuBarExtra(
            isInserted: listeningChromeBinding
        ) {
            ListeningMenuBarMenu(container: container)
        } label: {
            Label(
                "StudyFlow Listening",
                systemImage: ListeningMenuBarSymbol.systemName(for: container.voiceAgent.phase)
            )
        }
        .menuBarExtraStyle(.menu)
    }

    private var listeningChromeBinding: Binding<Bool> {
        Binding(
            get: { container.sessionChrome.isListeningChromeActive },
            set: { newValue in
                container.sessionChrome.isListeningChromeActive = newValue
                if !newValue {
                    // User removed the extra from Control Center — still restore the window.
                    MainWindowController.showAndActivateMainWindow()
                }
            }
        )
    }
}
