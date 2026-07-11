import Foundation
import Observation

/// Assembles multimodal study signals into a `StudyContext`.
///
/// Future work: window/app metadata, diffing consecutive OCR passes, speech windowing,
/// and debouncing so Behavior Analysis sees stable snapshots.
@Observable
@MainActor
final class ContextBuilder: ContextBuilding {
    private(set) var status: ServiceStatus = .notStarted

    func start() async throws {
        AppLogger.shared.info("ContextBuilder.start()", category: .context)
        status = .idle
    }

    func stop() async {
        AppLogger.shared.info("ContextBuilder.stop()", category: .context)
        status = .stopped
    }

    func buildContext(
        screenText: String,
        speech: [SpeechTranscript]
    ) async -> StudyContext {
        StudyContext(
            screenText: screenText,
            recentSpeech: speech,
            activitySummary: "Placeholder context — observation pipeline not active."
        )
    }
}
