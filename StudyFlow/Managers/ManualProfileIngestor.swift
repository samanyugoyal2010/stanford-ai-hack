import Foundation
import Observation

/// Ingests a typed or uploaded learner self-description into EverOS, then hybrid-refines with Gemma.
@Observable
@MainActor
final class ManualProfileIngestor {
    private let remoteMemory: EverOSMemoryService
    private let database: SQLiteStore
    private let hybridPipeline: HybridProfilePipeline
    private let log = PipelineActivityLog.shared

    private(set) var lastError: String?
    private(set) var lastProfile: LearnerProfileSnapshot?
    private(set) var isBusy = false

    init(
        remoteMemory: EverOSMemoryService,
        database: SQLiteStore,
        hybridPipeline: HybridProfilePipeline
    ) {
        self.remoteMemory = remoteMemory
        self.database = database
        self.hybridPipeline = hybridPipeline
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
            source: .manual,
            evidenceExcerpts: [trimmed]
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
            source: .upload,
            evidenceExcerpts: [trimmed]
        )
    }

    private func ingest(
        body: String,
        source: LearnerProfileSource,
        evidenceExcerpts: [String]
    ) async throws -> LearnerProfileSnapshot? {
        isBusy = true
        lastError = nil
        defer { isBusy = false }

        let sessionId = "manual_\(UUID().uuidString.lowercased())"
        let userId = remoteMemory.userId
        log.info("Describe", "Starting ingest · source=\(source.rawValue) · session=\(sessionId)")
        log.info("Describe", "Evidence length=\(evidenceExcerpts.joined().count) chars")

        do {
            log.info("EverOS", "addMessages…")
            try await remoteMemory.addMessages(
                userId: userId,
                sessionId: sessionId,
                messages: [.user(text: body)]
            )
            log.info("EverOS", "flush…")
            try await remoteMemory.flush(userId: userId, sessionId: sessionId)

            // Poll briefly — EverOS extraction is async.
            var base: LearnerProfileSnapshot?
            for attempt in 1...4 {
                log.info("EverOS", "fetchProfile attempt \(attempt)/4…")
                try await Task.sleep(nanoseconds: 1_500_000_000)
                if var profile = try await remoteMemory.fetchProfile(userId: userId) {
                    profile.source = source
                    base = profile
                    log.info(
                        "EverOS",
                        "Profile found · explicit=\(profile.explicitInfo.count) · implicit=\(profile.implicitTraits.count)"
                    )
                    break
                }
                log.info("EverOS", "No profile yet (extraction still running)")
            }

            let refined = await hybridPipeline.refine(
                baseProfile: base,
                sessionId: sessionId,
                samplesSent: 0,
                recentOCRExcerpts: evidenceExcerpts,
                intakeSource: source
            )
            lastProfile = refined
            if let refined {
                log.info("Describe", "Done · status=\(refined.synthesisStatus?.rawValue ?? "nil") · hasIdeal=\(refined.ideal != nil)")
            } else {
                log.error("Describe", "Pipeline returned nil snapshot")
            }
            return refined
        } catch {
            lastError = error.localizedDescription
            log.error("Describe", error.localizedDescription)
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
