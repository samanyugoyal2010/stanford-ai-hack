import Foundation
import Observation

/// High-level AI service that turns study context into Socratic guidance via Gemma 4.
@Observable
@MainActor
final class GemmaService: AIProviding {
    private(set) var status: ServiceStatus = .notStarted

    private let client: OllamaClient
    private let remoteMemory: EverOSMemoryService?
    private let database: SQLiteStore?

    init(
        client: OllamaClient = OllamaClient(),
        remoteMemory: EverOSMemoryService? = nil,
        database: SQLiteStore? = nil
    ) {
        self.client = client
        self.remoteMemory = remoteMemory
        self.database = database
    }

    func start() async throws {
        let reachable = await client.isReachable()
        status = reachable ? .idle : .failed("Ollama unreachable")
        if !reachable {
            throw OllamaError.unreachable
        }
        AppLogger.shared.info("GemmaService.start() — Ollama reachable", category: .ai)
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
        status = .running
        defer { status = .idle }

        let ideal = database.flatMap { try? $0.loadLearnerProfile()?.ideal }
        let personalized = await buildPersonalizedContext(topicHint: context.activitySummary)
        let prompt = SocraticPrompt.build(
            context: context,
            idealProfile: ideal,
            everOSSnippets: personalized,
            conversationHistory: []
        )
        _ = (insights, memories)
        return try await client.generate(prompt: prompt, formatJSON: false)
    }

    func streamGuidance(
        context: StudyContext,
        insights: [BehaviorInsight],
        memories: [MemoryEntry],
        conversationHistory: [(role: String, text: String)],
        idealProfile: IdealLearnerProfile?
    ) -> AsyncThrowingStream<String, Error> {
        let ideal = idealProfile ?? database.flatMap { try? $0.loadLearnerProfile()?.ideal }
        _ = (insights, memories)

        return AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                self.status = .running
                do {
                    let personalized = await self.buildPersonalizedContext(topicHint: context.activitySummary)
                    let prompt = SocraticPrompt.build(
                        context: context,
                        idealProfile: ideal,
                        everOSSnippets: personalized,
                        conversationHistory: conversationHistory
                    )
                    for try await chunk in await self.client.generateStream(prompt: prompt) {
                        if Task.isCancelled { break }
                        continuation.yield(chunk)
                    }
                    self.status = .idle
                    continuation.finish()
                } catch {
                    self.status = .failed(error.localizedDescription)
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Pulls EverOS profile + episodic snippets for prompt grounding.
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
