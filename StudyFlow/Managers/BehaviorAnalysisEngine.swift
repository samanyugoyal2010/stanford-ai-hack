import Foundation
import Observation

/// Infers study behavior from context to decide when Socratic help is useful.
///
/// Future work: heuristics + model-assisted classification for stuckness, guessing,
/// answer-seeking, and productive struggle — without spoiling solutions.
@Observable
@MainActor
final class BehaviorAnalysisEngine: BehaviorAnalyzing {
    private(set) var status: ServiceStatus = .notStarted

    func start() async throws {
        AppLogger.shared.info("BehaviorAnalysisEngine.start()", category: .behavior)
        status = .idle
    }

    func stop() async {
        AppLogger.shared.info("BehaviorAnalysisEngine.stop()", category: .behavior)
        status = .stopped
    }

    func analyze(context: StudyContext) async -> [BehaviorInsight] {
        // No insights until real analysis lands.
        _ = context
        return []
    }
}
