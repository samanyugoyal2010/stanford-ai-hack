import SwiftUI

/// Primary StudyFlow surface: Start/Stop voice tutoring + subsystem status cards.
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
                sessionPanel

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
        .task {
            await viewModel.refreshOllamaStatus()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(AppConstants.appName)
                .font(.largeTitle.weight(.bold))

            Text("AI-powered study companion — Start watches your screen and talks with you as a Socratic coach.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var sessionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if viewModel.isSessionActive {
                    Button("Stop") {
                        Task { await viewModel.stopSession() }
                    }
                    .disabled(viewModel.isStarting)

                    Text(viewModel.agentPhase.rawValue)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    if viewModel.samplesSent > 0 {
                        Text("Samples: \(viewModel.samplesSent)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button("Start") {
                        Task { await viewModel.startSession() }
                    }
                    .disabled(viewModel.isStarting || viewModel.ollamaReady == false)

                    if viewModel.isStarting {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                Spacer(minLength: 0)
            }

            if let error = viewModel.lastError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            if viewModel.isSessionActive {
                if !viewModel.lastUserUtterance.isEmpty {
                    Text("You: \(viewModel.lastUserUtterance)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if !viewModel.lastAgentReply.isEmpty {
                    Text("Coach: \(viewModel.lastAgentReply)")
                        .font(.callout)
                        .lineLimit(3)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel(container: AppDependencyContainer()))
        .frame(width: 800, height: 600)
}
