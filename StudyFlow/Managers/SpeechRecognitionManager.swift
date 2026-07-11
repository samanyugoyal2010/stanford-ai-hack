import Foundation
import Observation

/// Placeholder Apple Speech recognition manager.
///
/// Future work: configure `SFSpeechRecognizer`, request mic + speech permissions,
/// stream partial/final transcripts, and coordinate with `AudioCaptureConfigurator`.
@Observable
@MainActor
final class SpeechRecognitionManager: SpeechRecognizing {
    private(set) var status: ServiceStatus = .notStarted
    private var transcripts: [SpeechTranscript] = []

    private let audioConfigurator: AudioCaptureConfigurator

    init(audioConfigurator: AudioCaptureConfigurator = AudioCaptureConfigurator()) {
        self.audioConfigurator = audioConfigurator
    }

    func start() async throws {
        AppLogger.shared.info("SpeechRecognitionManager.start() — placeholder; mic not opened", category: .speech)
        _ = try await audioConfigurator.prepareSession()
        status = .idle
    }

    func stop() async {
        AppLogger.shared.info("SpeechRecognitionManager.stop()", category: .speech)
        await audioConfigurator.tearDown()
        transcripts = []
        status = .stopped
    }

    func recentTranscripts() async -> [SpeechTranscript] {
        transcripts
    }
}
