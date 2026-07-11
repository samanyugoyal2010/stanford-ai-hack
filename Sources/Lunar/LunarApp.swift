import SwiftUI

@main
struct LunarApp: App {
    @StateObject private var model = WorkspaceModel()

    var body: some Scene {
        WindowGroup("Lunar") {
            ContentView(model: model)
                .frame(minWidth: 980, minHeight: 680)
        }
        .windowStyle(.hiddenTitleBar)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
