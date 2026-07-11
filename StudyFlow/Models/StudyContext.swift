import Foundation

/// Unified snapshot of what the student is currently doing, built from OCR and speech.
///
/// The Context Builder merges multimodal signals into this structure before behavior
/// analysis and AI guidance run.
struct StudyContext: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    /// Latest on-screen text summary from Vision OCR.
    let screenText: String
    /// Recent spoken utterances from the student.
    let recentSpeech: [SpeechTranscript]
    /// Free-form notes about the active application or study material.
    let activitySummary: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        screenText: String = "",
        recentSpeech: [SpeechTranscript] = [],
        activitySummary: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.screenText = screenText
        self.recentSpeech = recentSpeech
        self.activitySummary = activitySummary
    }
}
