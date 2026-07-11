import SwiftUI

/// Primary StudyFlow surface: a grid of subsystem status cards.
struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.statusCards) { card in
                        StatusCardView(model: card)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 900, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(AppConstants.appName)
                .font(.largeTitle.weight(.bold))

            Text("AI-powered study companion — use Learner Profile to observe a session or describe how you learn.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel(container: AppDependencyContainer()))
        .frame(width: 800, height: 600)
}
