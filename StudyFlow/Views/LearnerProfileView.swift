import SwiftUI
import UniformTypeIdentifiers

/// Setup surface for ideal learner profile: observe, describe, or upload.
struct LearnerProfileView: View {
    @Bindable var viewModel: LearnerProfileViewModel
    @State private var isFileImporterPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                apiKeyBanner
                Picker("Mode", selection: $viewModel.selectedTab) {
                    ForEach(LearnerProfileViewModel.ProfileTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch viewModel.selectedTab {
                case .observe:
                    observePanel
                case .describe:
                    describePanel
                case .upload:
                    uploadPanel
                }

                if let status = viewModel.statusMessage {
                    Text(status)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                }

                profileSummary
            }
            .padding(24)
            .frame(maxWidth: 900, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor))
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.plainText, .utf8PlainText, UTType(filenameExtension: "md") ?? .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task { await viewModel.importFile(url: url) }
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Learner Profile")
                .font(.largeTitle.weight(.bold))
            Text("Teach StudyFlow how you learn — by watching a study session, describing yourself, or uploading a profile.")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("EverOS user: \(viewModel.everOSUserId)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private var apiKeyBanner: some View {
        if !viewModel.hasAPIKey {
            Text("Set EVEROS_API_KEY in the Xcode scheme’s Environment Variables (Product → Scheme → Edit Scheme → Run → Arguments).")
                .font(.callout)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var observePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Observe a study session")
                .font(.title2.weight(.semibold))
            Text("StudyFlow captures your screen, reads on-screen text, and sends first-person study observations to EverOS. When you stop, EverOS consolidates a durable learner profile.")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button(viewModel.isObserving ? "Observing…" : "Start Observation") {
                    Task { await viewModel.startObservation() }
                }
                .disabled(viewModel.isObserving || !viewModel.hasAPIKey)

                Button("Stop & Extract Profile") {
                    Task { await viewModel.stopObservation() }
                }
                .disabled(!viewModel.isObserving)

                Button("Refresh Profile") {
                    Task { await viewModel.refreshProfile() }
                }
                .disabled(!viewModel.hasAPIKey)
            }

            if viewModel.isObserving {
                Text("Samples sent: \(viewModel.samplesSent)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(panelBackground)
    }

    private var describePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Describe your learner profile")
                .font(.title2.weight(.semibold))
            Text("Write how you learn best, subjects you struggle with, and what kind of help works for you.")
                .foregroundStyle(.secondary)

            TextEditor(text: $viewModel.describeText)
                .font(.body)
                .frame(minHeight: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                )

            Button("Save Description") {
                Task { await viewModel.saveDescription() }
            }
            .disabled(viewModel.describeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !viewModel.hasAPIKey)
        }
        .padding(16)
        .background(panelBackground)
    }

    private var uploadPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upload a profile file")
                .font(.title2.weight(.semibold))
            Text("Import a .txt or .md file that describes your learning style.")
                .foregroundStyle(.secondary)

            Button("Choose File…") {
                isFileImporterPresented = true
            }
            .disabled(!viewModel.hasAPIKey)
        }
        .padding(16)
        .background(panelBackground)
    }

    private var profileSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current profile")
                .font(.title2.weight(.semibold))

            if let profile = viewModel.profile, !profile.isEmpty {
                Text("Source: \(profile.source.rawValue) · Updated \(profile.updatedAt.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(profile.displayLines, id: \.self) { line in
                    Text(line)
                        .font(.body)
                }
            } else {
                Text("No profile extracted yet.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor))
    }
}
