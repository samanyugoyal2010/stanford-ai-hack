import Foundation

/// Local LLM interface used to generate Socratic study guidance.
///
/// Concrete implementations talk to Ollama (Gemma 4). This milestone does not
/// perform real inference — responses are empty placeholders.
@MainActor
protocol AIProviding: AnyObject {
    /// Current lifecycle status for dashboard / diagnostics.
    var status: ServiceStatus { get }

    /// Prepare the AI client (connectivity checks come later).
    func start() async throws

    /// Tear down the AI client.
    func stop() async

    /// Generate a Socratic guidance response from context + insights + memories.
    /// Must not reveal direct answers when real reasoning is implemented.
    func generateGuidance(
        context: StudyContext,
        insights: [BehaviorInsight],
        memories: [MemoryEntry]
    ) async throws -> String
}
