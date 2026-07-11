import Foundation
import Observation

/// Assembles multimodal study signals into a `StudyContext`.
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
        status = .running
        defer { status = .idle }

        let trimmedScreen = screenText.trimmingCharacters(in: .whitespacesAndNewlines)
        let recentFinals = speech.filter(\.isFinal).suffix(6)
        let lastUtterance = recentFinals.last?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let summary: String
        if !lastUtterance.isEmpty, !trimmedScreen.isEmpty {
            summary = "Student said: \(String(lastUtterance.prefix(160))). Screen shows study material."
        } else if !lastUtterance.isEmpty {
            summary = "Student said: \(String(lastUtterance.prefix(200)))."
        } else if !trimmedScreen.isEmpty {
            summary = "Student is viewing on-screen material; waiting for a question."
        } else {
            summary = "Live tutoring session — limited context so far."
        }

        return StudyContext(
            screenText: String(trimmedScreen.prefix(1200)),
            recentSpeech: Array(speech.suffix(8)),
            activitySummary: summary
        )
    }
}
