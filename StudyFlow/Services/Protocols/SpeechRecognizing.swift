import Foundation

/// Converts live microphone audio into study-session transcripts.
///
/// Concrete implementations use Apple's Speech framework and AVFoundation.
@MainActor
protocol SpeechRecognizing: AnyObject {
    /// Current lifecycle status for dashboard / diagnostics.
    var status: ServiceStatus { get }

    /// Begin listening / recognition.
    func start() async throws

    /// Stop recognition and release audio resources.
    func stop() async

    /// Returns recent transcript segments collected during this session.
    func recentTranscripts() async -> [SpeechTranscript]

    /// Stream of finalized utterances for the voice-agent turn loop.
    var finalUtteranceStream: AsyncStream<SpeechTranscript> { get }

    /// Stream of partial/final updates (used for barge-in while the agent is speaking).
    var liveTranscriptStream: AsyncStream<SpeechTranscript> { get }
}
