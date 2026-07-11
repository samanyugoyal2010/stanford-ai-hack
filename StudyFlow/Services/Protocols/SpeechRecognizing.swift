import Foundation

/// Converts live microphone audio into study-session transcripts.
///
/// Concrete implementations will use Apple's Speech framework and AVFoundation.
@MainActor
protocol SpeechRecognizing: AnyObject {
    /// Current lifecycle status for dashboard / diagnostics.
    var status: ServiceStatus { get }

    /// Begin listening / recognition. Placeholder does not open the mic yet.
    func start() async throws

    /// Stop recognition and release audio resources.
    func stop() async

    /// Returns recent transcript segments collected during this session.
    func recentTranscripts() async -> [SpeechTranscript]
}
