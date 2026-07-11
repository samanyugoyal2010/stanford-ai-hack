import Foundation

/// Configures AVFoundation audio session / input routing for speech recognition.
///
/// Future work: select the default input device, handle route changes, and
/// coordinate with `SFSpeechAudioBufferRecognitionRequest`.
struct AudioCaptureConfigurator: Sendable {
    /// Prepare audio input for recognition. Placeholder performs no AV setup.
    func prepareSession() async throws -> Bool {
        AppLogger.shared.debug("AudioCaptureConfigurator.prepareSession() stub", category: .audio)
        return true
    }

    /// Release audio resources. Placeholder is a no-op.
    func tearDown() async {
        AppLogger.shared.debug("AudioCaptureConfigurator.tearDown() stub", category: .audio)
    }
}
