import Foundation
import Observation
import UniformTypeIdentifiers

/// Drives the Learner Profile setup UI (observe / describe / upload).
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
        statusMessage = "Stopping and asking EverOS to extract your learner profile…"
        do {
            if let snapshot = try await container.observationCoordinator.stopSession() {
                profile = snapshot
                statusMessage = "Profile updated from observation."
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
        statusMessage = "Saving description to EverOS…"
        do {
            if let snapshot = try await container.manualProfileIngestor.ingestDescription(describeText) {
                profile = snapshot
                statusMessage = "Profile updated from your description."
            } else {
                statusMessage = "Saved. Profile may still be extracting — try Refresh."
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
                statusMessage = "Profile updated from uploaded file."
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
        statusMessage = "Refreshing profile from EverOS…"
        do {
            if let snapshot = try await container.remoteMemory.fetchProfile(userId: everOSUserId) {
                profile = snapshot
                try? container.database.saveLearnerProfile(snapshot)
                statusMessage = "Profile refreshed."
            } else {
                statusMessage = "No profile found yet for this user."
            }
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = nil
        }
    }
}
