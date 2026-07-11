import Foundation
import Observation
import UniformTypeIdentifiers

/// Drives the Learner Profile setup UI (observe / describe / upload + hybrid status).
@Observable
@MainActor
final class LearnerProfileViewModel {
    private let container: AppDependencyContainer

    var describeText: String = ""
    var statusMessage: String?
    var errorMessage: String?
    var profile: LearnerProfileSnapshot?
    var selectedTab: ProfileTab = .observe

    enum ProfileTab: String, CaseIterable, Identifiable {
        case observe = "Observe"
        case describe = "Describe"
        case upload = "Upload"

        var id: String { rawValue }
    }

    init(container: AppDependencyContainer) {
        self.container = container
        if let cached = try? container.database.loadLearnerProfile() {
            self.profile = cached
        } else {
            self.profile = container.observationCoordinator.lastProfile
                ?? container.manualProfileIngestor.lastProfile
        }
    }

    var isObserving: Bool {
        container.observationCoordinator.isRunning
    }

    var samplesSent: Int {
        container.observationCoordinator.samplesSent
    }

    var everOSUserId: String {
        container.remoteMemory.userId
    }

    var hasAPIKey: Bool {
        EverOSCredentialStore().apiKey() != nil
    }

    var hybridStatus: HybridSynthesisStatus {
        profile?.synthesisStatus
            ?? container.hybridPipeline.status
    }

    var ollamaModelName: String {
        AppConstants.defaultModelName
    }

    var activityLog: PipelineActivityLog {
        PipelineActivityLog.shared
    }

    var isBusy: Bool {
        container.manualProfileIngestor.isBusy
            || container.observationCoordinator.isRunning
            || container.hybridPipeline.status == .gemmaSynthesizing
            || container.hybridPipeline.status == .everOSExtracted
    }

    func clearActivityLog() {
        activityLog.clear()
    }

    func startObservation() async {
        errorMessage = nil
        statusMessage = "Starting screen observation…"
        do {
            try await container.observationCoordinator.startSession()
            statusMessage = "Observing study session. Study normally — StudyFlow is watching quietly."
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = nil
        }
    }

    func stopObservation() async {
        errorMessage = nil
        statusMessage = "EverOS extracting… then Gemma will synthesize your ideal profile."
        do {
            if let snapshot = try await container.observationCoordinator.stopSession() {
                profile = snapshot
                statusMessage = snapshot.synthesisStatus?.displayMessage
                    ?? "Profile updated from observation."
                if snapshot.synthesisStatus == .gemmaUnavailable {
                    errorMessage = container.hybridPipeline.lastError
                }
            } else {
                statusMessage = "Session saved. Profile may still be extracting — try Refresh."
            }
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = nil
        }
    }

    func saveDescription() async {
        errorMessage = nil
        statusMessage = "Saving to EverOS… then Gemma will synthesize your ideal profile."
        do {
            if let snapshot = try await container.manualProfileIngestor.ingestDescription(describeText) {
                profile = snapshot
                if let ideal = snapshot.ideal, !ideal.isEmpty {
                    statusMessage = "Ideal profile ready (\(snapshot.synthesisStatus?.displayMessage ?? "done"))."
                } else if snapshot.synthesisStatus == .gemmaUnavailable {
                    statusMessage = HybridSynthesisStatus.gemmaUnavailable.displayMessage
                    errorMessage = container.hybridPipeline.lastError
                } else {
                    statusMessage = "Saved — EverOS traits may still be thin; ideal synthesis used your description."
                }
            } else {
                statusMessage = "Save finished but no snapshot returned — check Activity Log."
                errorMessage = container.manualProfileIngestor.lastError
                    ?? container.hybridPipeline.lastError
            }
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = nil
        }
    }

    func importFile(url: URL) async {
        errorMessage = nil
        statusMessage = "Importing \(url.lastPathComponent)…"
        do {
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess { url.stopAccessingSecurityScopedResource() }
            }
            let text = try String(contentsOf: url, encoding: .utf8)
            if let snapshot = try await container.manualProfileIngestor.ingestFileContents(
                text,
                fileName: url.lastPathComponent
            ) {
                profile = snapshot
                statusMessage = snapshot.synthesisStatus?.displayMessage
                    ?? "Profile updated from uploaded file."
                if snapshot.synthesisStatus == .gemmaUnavailable {
                    errorMessage = container.hybridPipeline.lastError
                }
            } else {
                statusMessage = "Uploaded. Profile may still be extracting — try Refresh."
            }
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = nil
        }
    }

    func refreshProfile() async {
        errorMessage = nil
        statusMessage = "Refreshing from EverOS + Gemma…"
        do {
            let base = try await container.remoteMemory.fetchProfile(userId: everOSUserId)
            let refined = await container.hybridPipeline.refine(
                baseProfile: base,
                sessionId: nil,
                samplesSent: 0,
                recentOCRExcerpts: [],
                intakeSource: .remote
            )
            if let refined {
                profile = refined
                statusMessage = refined.synthesisStatus?.displayMessage ?? "Profile refreshed."
                if refined.synthesisStatus == .gemmaUnavailable {
                    errorMessage = container.hybridPipeline.lastError
                }
            } else {
                statusMessage = "No profile found yet for this user."
            }
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = nil
        }
    }
}
