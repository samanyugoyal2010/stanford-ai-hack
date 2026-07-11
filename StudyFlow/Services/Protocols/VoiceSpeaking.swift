import Foundation

/// Speaks AI guidance aloud to the student.
///
/// Concrete implementations will use AVFoundation speech synthesis (or similar).
@MainActor
protocol VoiceSpeaking: AnyObject {
    /// Current lifecycle status for dashboard / diagnostics.
    var status: ServiceStatus { get }

    /// Prepare the speech synthesizer.
    func start() async throws

    /// Stop playback and release audio resources.
    func stop() async

    /// Speak the provided guidance text. Placeholder is a no-op.
    func speak(_ text: String) async throws
}
