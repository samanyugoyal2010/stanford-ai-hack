import Foundation
import Observation

/// Speaks AI guidance to the student using system speech synthesis (future).
///
/// Future work: `AVSpeechSynthesizer` voice selection, interruption when new
/// guidance arrives, and mute controls from the dashboard.
@Observable
@MainActor
final class VoiceOutputManager: VoiceSpeaking {
    private(set) var status: ServiceStatus = .notStarted

    func start() async throws {
        AppLogger.shared.info("VoiceOutputManager.start() — placeholder; no TTS yet", category: .voice)
        status = .idle
    }

    func stop() async {
        AppLogger.shared.info("VoiceOutputManager.stop()", category: .voice)
        status = .stopped
    }

    func speak(_ text: String) async throws {
        let preview = String(text.prefix(80))
        AppLogger.shared.debug("VoiceOutputManager.speak ignored: \(preview)", category: .voice)
    }
}
