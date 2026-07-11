import Foundation

/// Local LLM interface used to generate Socratic study guidance.
///
/// Concrete implementations talk to Ollama (Gemma 4).
@MainActor
protocol AIProviding: AnyObject {
    /// Current lifecycle status for dashboard / diagnostics.
    var status: ServiceStatus { get }

    /// Prepare the AI client (connectivity checks).
    func start() async throws

    /// Tear down the AI client.
    func stop() async

    /// Generate a Socratic guidance response from context + insights + memories.
    /// Must not reveal direct answers.
    func generateGuidance(
        context: StudyContext,
        insights: [BehaviorInsight],
        memories: [MemoryEntry]
    ) async throws -> String

    /// Stream a Socratic reply as text chunks for low-latency TTS.
    func streamGuidance(
        context: StudyContext,
        insights: [BehaviorInsight],
        memories: [MemoryEntry],
        conversationHistory: [(role: String, text: String)],
        idealProfile: IdealLearnerProfile?
    ) -> AsyncThrowingStream<String, Error>
}
