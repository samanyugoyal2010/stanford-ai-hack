import Foundation
import Observation

/// High-level AI service that turns study context into Socratic guidance via Gemma 4.
///
/// Profile extraction is owned by EverOS. This service will later *consume* retrieved
/// profile/episodes when building Socratic prompts — never reveal direct homework answers.
@Observable
@MainActor
final class GemmaService: AIProviding {
    private(set) var status: ServiceStatus = .notStarted

    private let client: OllamaClient
    private let remoteMemory: EverOSMemoryService?

    init(client: OllamaClient = OllamaClient(), remoteMemory: EverOSMemoryService? = nil) {
        self.client = client
        self.remoteMemory = remoteMemory
    }

    func start() async throws {
        AppLogger.shared.info("GemmaService.start() — AI reasoning not implemented yet", category: .ai)
        _ = await client.isReachable()
        status = .idle
    }

    func stop() async {
        AppLogger.shared.info("GemmaService.stop()", category: .ai)
        status = .stopped
    }

    func generateGuidance(
        context: StudyContext,
        insights: [BehaviorInsight],
        memories: [MemoryEntry]
    ) async throws -> String {
        let personalized = await buildPersonalizedContext(topicHint: context.activitySummary)
        _ = (context, insights, memories, personalized)
        // Intentionally empty until the Socratic prompt pipeline is built.
        return try await client.generate(prompt: "")
    }

    /// Pulls EverOS profile + episodic snippets for future Gemma prompt grounding.
    func buildPersonalizedContext(topicHint: String) async -> String {
        guard let remoteMemory else { return "" }
        do {
            let result = try await remoteMemory.search(
                userId: remoteMemory.userId,
                query: topicHint.isEmpty ? "learning style preferences strengths struggles" : topicHint,
                memoryTypes: ["profile", "episodic_memory"],
                topK: 5
            )
            return result.rawSnippet
        } catch {
            AppLogger.shared.debug(
                "buildPersonalizedContext skipped: \(error.localizedDescription)",
                category: .ai
            )
            return ""
        }
    }
}
