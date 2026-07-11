import SwiftUI
import UniformTypeIdentifiers

/// Setup surface for ideal learner profile: observe, describe, or upload + hybrid Gemma card.
struct LearnerProfileView: View {
    @Bindable var viewModel: LearnerProfileViewModel
    @State private var isFileImporterPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                hybridStatusBanner
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

                idealProfileCard
                rawProfileSummary
                activityLogPanel
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
            Text("EverOS extracts traits from observation or your description; local Gemma fills a fixed ideal learner profile.")
                .font(.body)
                .foregroundStyle(.secondary)
                        Text("EverOS user: \(viewModel.everOSUserId) · Ollama model: \(viewModel.ollamaModelName)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
            Text("Console tip: Console.app → search subsystem `com.studyflow.app`")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var hybridStatusBanner: some View {
        Text(viewModel.hybridStatus.displayMessage)
            .font(.callout.weight(.medium))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(statusBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var statusBackground: Color {
        switch viewModel.hybridStatus {
        case .ready:
            return Color.green.opacity(0.15)
        case .gemmaUnavailable:
            return Color.orange.opacity(0.15)
        case .gemmaSynthesizing, .everOSExtracted:
            return Color.blue.opacity(0.12)
        case .idle:
            return Color.primary.opacity(0.06)
        }
    }

    @ViewBuilder
    private var apiKeyBanner: some View {
        if !viewModel.hasAPIKey {
            Text("Set EVEROS_API_KEY in the Xcode scheme’s Environment Variables.")
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
            Text("StudyFlow captures your screen and sends observations to EverOS. On stop, Gemma synthesizes your ideal learner profile.")
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

    @ViewBuilder
    private var idealProfileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ideal Learner Profile")
                .font(.title2.weight(.semibold))

            if let ideal = viewModel.profile?.ideal, !ideal.isEmpty {
                Text(ideal.summary)
                    .font(.body)

                labeledRow("Learning style", ideal.learningStyle)
                labeledRow("Preferred help", ideal.preferredHelp)
                labeledRow("Confidence", String(format: "%.0f%%", ideal.confidence * 100))

                if !ideal.strengths.isEmpty {
                    labeledRow("Strengths", ideal.strengths.joined(separator: " · "))
                }
                if !ideal.struggles.isEmpty {
                    labeledRow("Struggles", ideal.struggles.joined(separator: " · "))
                }
                if !ideal.motivationTriggers.isEmpty {
                    labeledRow("Motivation", ideal.motivationTriggers.joined(separator: " · "))
                }
                if !ideal.subjectHints.isEmpty {
                    labeledRow("Subjects", ideal.subjectHints.joined(separator: " · "))
                }
                if !ideal.evidenceNotes.isEmpty {
                    labeledRow("Evidence", ideal.evidenceNotes.joined(separator: " · "))
                }
            } else {
                Text("No ideal profile yet. Complete Observe / Describe / Upload (with Ollama running) to synthesize one.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
    }

    private var rawProfileSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EverOS raw traits")
                .font(.title2.weight(.semibold))

            if let profile = viewModel.profile, !profile.displayLines.isEmpty {
                Text("Source: \(profile.source.rawValue) · Updated \(profile.updatedAt.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(profile.displayLines, id: \.self) { line in
                    Text(line)
                        .font(.body)
                }
            } else {
                Text("No EverOS traits extracted yet.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
    }

    private var activityLogPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity Log")
                    .font(.title2.weight(.semibold))
                Spacer()
                if viewModel.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
                Button("Clear") {
                    viewModel.clearActivityLog()
                }
                .disabled(viewModel.activityLog.entries.isEmpty)
            }

            Text("Live pipeline steps (also in Console.app → filter subsystem com.studyflow.app).")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.activityLog.entries.isEmpty {
                Text("No events yet — Save Description or Start Observation to begin.")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(viewModel.activityLog.entries.reversed()) { entry in
                            Text(entry.displayLine)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(entry.isError ? Color.red : Color.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                }
                .frame(minHeight: 140, maxHeight: 220)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "—" : value)
                .font(.body)
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor))
    }
}
