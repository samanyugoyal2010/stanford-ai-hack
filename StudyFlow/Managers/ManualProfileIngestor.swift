import Foundation
import Observation

/// Ingests a typed or uploaded learner self-description into EverOS as profile memory.
@Observable
@MainActor
final class ManualProfileIngestor {
    private let remoteMemory: EverOSMemoryService
    private let database: SQLiteStore

    private(set) var lastError: String?
    private(set) var lastProfile: LearnerProfileSnapshot?
    private(set) var isBusy = false

    init(remoteMemory: EverOSMemoryService, database: SQLiteStore) {
        self.remoteMemory = remoteMemory
        self.database = database
    }

    /// Saves a free-text learner profile description.
    func ingestDescription(_ text: String) async throws -> LearnerProfileSnapshot? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw IngestError.emptyContent
        }
        return try await ingest(
            body: """
            Here is my learner profile in my own words. Please remember these as lasting traits \
            about how I learn, what I struggle with, and what helps me:

            \(trimmed)
            """,
            source: .manual
        )
    }

    /// Saves contents of a `.txt` / `.md` learner profile file.
    func ingestFileContents(_ text: String, fileName: String) async throws -> LearnerProfileSnapshot? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw IngestError.emptyContent
        }
        return try await ingest(
            body: """
            I uploaded my learner profile file named \(fileName). Treat the following as my \
            durable learning preferences, strengths, and challenges:

            \(trimmed)
            """,
            source: .upload
        )
    }

    private func ingest(body: String, source: LearnerProfileSource) async throws -> LearnerProfileSnapshot? {
        isBusy = true
        lastError = nil
        defer { isBusy = false }

        let sessionId = "manual_\(UUID().uuidString.lowercased())"
        let userId = remoteMemory.userId

        do {
            try await remoteMemory.addMessages(
                userId: userId,
                sessionId: sessionId,
                messages: [.user(text: body)]
            )
            try await remoteMemory.flush(userId: userId, sessionId: sessionId)
            try await Task.sleep(nanoseconds: 1_500_000_000)

            if var profile = try await remoteMemory.fetchProfile(userId: userId) {
                profile.source = source
                lastProfile = profile
                try? database.open()
                try? database.saveLearnerProfile(profile)
                return profile
            }
            return nil
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    enum IngestError: Error, LocalizedError {
        case emptyContent

        var errorDescription: String? {
            switch self {
            case .emptyContent:
                return "Profile text is empty."
            }
        }
    }
}
