import Foundation

/// A segment of recognized speech from the student during a study session.
struct SpeechTranscript: Identifiable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    /// Recognized utterance text.
    let text: String
    /// Whether Apple Speech considers this a final (non-partial) result.
    let isFinal: Bool
    /// Optional recognition confidence when the framework provides one.
    let confidence: Float?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        text: String,
        isFinal: Bool = true,
        confidence: Float? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
        self.isFinal = isFinal
        self.confidence = confidence
    }
}
