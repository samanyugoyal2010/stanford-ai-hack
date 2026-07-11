import Foundation

/// Speaks AI guidance aloud to the student.
///
/// Concrete implementations use AVFoundation speech synthesis.
@MainActor
protocol VoiceSpeaking: AnyObject {
    /// Current lifecycle status for dashboard / diagnostics.
    var status: ServiceStatus { get }

    /// Whether the synthesizer is currently speaking.
    var isSpeaking: Bool { get }

    /// Prepare the speech synthesizer.
    func start() async throws

    /// Stop playback and release audio resources.
    func stop() async

    /// Speak the provided guidance text. Completes when the utterance finishes or is interrupted.
    func speak(_ text: String) async throws

    /// Immediately stop any in-progress utterance (barge-in).
    func interrupt()
}
