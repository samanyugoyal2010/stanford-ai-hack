import Foundation
import Observation

/// Orchestrates EverOS extraction → Gemma ideal-profile synthesis → write-back + cache.
@Observable
@MainActor
final class HybridProfilePipeline {
    private let remoteMemory: EverOSMemoryService
    private let synthesizer: LearnerProfileSynthesizer
    private let database: SQLiteStore
    private let log = PipelineActivityLog.shared

    private(set) var status: HybridSynthesisStatus = .idle
    private(set) var lastError: String?

    init(
        remoteMemory: EverOSMemoryService,
        synthesizer: LearnerProfileSynthesizer,
        database: SQLiteStore
    ) {
        self.remoteMemory = remoteMemory
        self.synthesizer = synthesizer
        self.database = database
    }

    /// Runs hybrid synthesis after EverOS flush.
    /// If EverOS has no profile yet, still synthesizes from local evidence (description / OCR).
    func refine(
        baseProfile: LearnerProfileSnapshot?,
        sessionId: String?,
        samplesSent: Int,
        recentOCRExcerpts: [String],
        intakeSource: LearnerProfileSource
    ) async -> LearnerProfileSnapshot? {
        lastError = nil
        let userId = remoteMemory.userId
        log.info("Hybrid", "Starting refine · user=\(userId) · source=\(intakeSource.rawValue) · session=\(sessionId ?? "none")")

        var working = baseProfile
        if working == nil {
            log.info("EverOS", "No base profile yet — fetching again…")
            working = try? await remoteMemory.fetchProfile(userId: userId)
        }

        // Provisional snapshot so Gemma can still run from local evidence.
        if working == nil {
            log.info("Hybrid", "EverOS profile empty — building provisional snapshot from local evidence")
            working = LearnerProfileSnapshot(
                userId: userId,
                explicitInfo: recentOCRExcerpts.isEmpty
                    ? [:]
                    : ["pending_description": String(recentOCRExcerpts.joined(separator: " ").prefix(500))],
                implicitTraits: [:],
                source: intakeSource,
                synthesisStatus: .everOSExtracted
            )
        }

        guard var snapshot = working else {
            log.error("Hybrid", "Could not build a working snapshot")
            status = .idle
            return nil
        }

        snapshot.source = intakeSource
        status = .everOSExtracted
        log.info(
            "EverOS",
            "Traits · explicit=\(snapshot.explicitInfo.count) · implicit=\(snapshot.implicitTraits.count)"
        )

        log.info("EverOS", "Searching episodic + profile memories…")
        let search = try? await remoteMemory.search(
            userId: userId,
            query: "learning style strengths struggles study habits preferred help",
            memoryTypes: ["profile", "episodic_memory"],
            topK: 8
        )
        log.info(
            "EverOS",
            "Search hits · episodes=\(search?.episodesSummary.count ?? 0) · profiles=\(search?.profilesSummary.count ?? 0)"
        )

        let input = ProfileSynthesisInput(
            userId: userId,
            sessionId: sessionId,
            samplesSent: samplesSent,
            everOSExplicitInfo: snapshot.explicitInfo,
            everOSImplicitTraits: snapshot.implicitTraits,
            episodeSnippets: search?.episodesSummary ?? [],
            profileSnippets: search?.profilesSummary ?? [],
            recentOCRExcerpts: recentOCRExcerpts,
            intakeSource: intakeSource
        )

        status = .gemmaSynthesizing
        log.info("Gemma", "Synthesizing IdealLearnerProfile via Ollama (\(AppConstants.defaultModelName))…")

        do {
            let ideal = try await synthesizer.synthesize(from: input)
            snapshot.ideal = ideal
            snapshot.source = .hybrid
            snapshot.synthesisStatus = .ready
            snapshot.updatedAt = Date()
            status = .ready

            try? database.open()
            try? database.saveLearnerProfile(snapshot)

            log.info(
                "Gemma",
                "Ideal profile ready · confidence=\(String(format: "%.2f", ideal.confidence)) · style=\(ideal.learningStyle)"
            )
            await writeBackToEverOS(ideal: ideal, sessionId: sessionId)
            return snapshot
        } catch {
            lastError = error.localizedDescription
            snapshot.synthesisStatus = .gemmaUnavailable
            snapshot.updatedAt = Date()
            status = .gemmaUnavailable
            try? database.open()
            try? database.saveLearnerProfile(snapshot)
            log.error("Gemma", "Unavailable — \(error.localizedDescription)")
            log.info("Hybrid", "Returning EverOS/provisional traits without ideal profile")
            return snapshot
        }
    }

    private func writeBackToEverOS(ideal: IdealLearnerProfile, sessionId: String?) async {
        let writeSession = sessionId.map { "ideal_\($0)" } ?? "ideal_\(UUID().uuidString.lowercased())"
        log.info("EverOS", "Writing ideal profile back…")
        do {
            try await remoteMemory.addMessages(
                userId: remoteMemory.userId,
                sessionId: writeSession,
                messages: [.user(text: ideal.everOSWriteBackMessage())]
            )
            try await remoteMemory.flush(userId: remoteMemory.userId, sessionId: writeSession)
            log.info("EverOS", "Ideal profile write-back flushed")
        } catch {
            log.error("EverOS", "Write-back skipped — \(error.localizedDescription)")
        }
    }
}
