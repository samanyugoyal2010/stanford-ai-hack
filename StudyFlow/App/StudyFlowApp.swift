import SwiftUI

/// StudyFlow application entry point (SwiftUI app lifecycle).
///
/// Owns the dependency container for the process lifetime and injects it into
/// the view hierarchy via the Observation environment. No observation pipeline
/// is started in this skeleton.
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
    }
}
