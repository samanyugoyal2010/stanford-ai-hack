import Foundation

/// Interprets study context to infer how the student is behaving (stuck, exploring, etc.).
///
/// This stage informs when and how Gemma should intervene with Socratic prompts.
@MainActor
protocol BehaviorAnalyzing: AnyObject {
    /// Current lifecycle status for dashboard / diagnostics.
    var status: ServiceStatus { get }

    /// Enable behavior analysis.
    func start() async throws

    /// Disable behavior analysis.
    func stop() async

    /// Analyze a context snapshot and return zero or more insights.
    func analyze(context: StudyContext) async -> [BehaviorInsight]
}
