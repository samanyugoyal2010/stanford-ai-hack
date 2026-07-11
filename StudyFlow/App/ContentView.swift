import SwiftUI

/// Root content shell with Dashboard and Learner Profile tabs.
struct ContentView: View {
    @Environment(AppDependencyContainer.self) private var container
    @State private var dashboardViewModel: DashboardViewModel?
    @State private var profileViewModel: LearnerProfileViewModel?

    var body: some View {
        TabView {
            Group {
                if let dashboardViewModel {
                    DashboardView(viewModel: dashboardViewModel)
                } else {
                    ProgressView("Starting StudyFlow…")
                }
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }

            Group {
                if let profileViewModel {
                    LearnerProfileView(viewModel: profileViewModel)
                } else {
                    ProgressView("Loading profile…")
                }
            }
            .tabItem { Label("Learner Profile", systemImage: "person.crop.circle") }
        }
        .onAppear {
            if dashboardViewModel == nil {
                dashboardViewModel = DashboardViewModel(container: container)
            }
            if profileViewModel == nil {
                profileViewModel = LearnerProfileViewModel(container: container)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppDependencyContainer())
        .frame(width: 900, height: 640)
}
