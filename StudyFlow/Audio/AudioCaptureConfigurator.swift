import AVFoundation
import Foundation

enum AudioCaptureError: Error, LocalizedError {
    case noInputDevice

    var errorDescription: String? {
        switch self {
        case .noInputDevice:
            return "No microphone input device found. Connect a mic and grant Microphone permission."
        }
    }
}

/// Validates AVFoundation audio input availability for speech recognition on macOS.
struct AudioCaptureConfigurator: Sendable {
    /// Ensures a default audio input device exists before recognition starts.
    func prepareSession() async throws -> Bool {
        guard AVCaptureDevice.default(for: .audio) != nil else {
            throw AudioCaptureError.noInputDevice
        }
        AppLogger.shared.debug("AudioCaptureConfigurator.prepareSession() ready", category: .audio)
        return true
    }

    /// Release audio resources (engine lifecycle owned by SpeechRecognitionManager).
    func tearDown() async {
        AppLogger.shared.debug("AudioCaptureConfigurator.tearDown()", category: .audio)
    }
}
