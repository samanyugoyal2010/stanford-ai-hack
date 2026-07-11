import Foundation

/// Fixed schema for StudyFlow's ideal learner profile, produced by local Gemma.
struct IdealLearnerProfile: Codable, Sendable, Equatable {
    var learningStyle: String
    var strengths: [String]
    var struggles: [String]
    var preferredHelp: String
    var motivationTriggers: [String]
    var subjectHints: [String]
    var confidence: Double
    var summary: String
    var evidenceNotes: [String]

    init(
        learningStyle: String = "",
        strengths: [String] = [],
        struggles: [String] = [],
        preferredHelp: String = "",
        motivationTriggers: [String] = [],
        subjectHints: [String] = [],
        confidence: Double = 0,
        summary: String = "",
        evidenceNotes: [String] = []
    ) {
        self.learningStyle = learningStyle
        self.strengths = strengths
        self.struggles = struggles
        self.preferredHelp = preferredHelp
        self.motivationTriggers = motivationTriggers
        self.subjectHints = subjectHints
        self.confidence = min(max(confidence, 0), 1)
        self.summary = summary
        self.evidenceNotes = evidenceNotes
    }

    /// Normalize decoded model output (clamp confidence, trim blanks).
    mutating func sanitize() {
        learningStyle = learningStyle.trimmingCharacters(in: .whitespacesAndNewlines)
        preferredHelp = preferredHelp.trimmingCharacters(in: .whitespacesAndNewlines)
        summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        strengths = strengths.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        struggles = struggles.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        motivationTriggers = motivationTriggers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        subjectHints = subjectHints.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        evidenceNotes = evidenceNotes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        confidence = min(max(confidence, 0), 1)
    }

    var isEmpty: Bool {
        summary.isEmpty
            && learningStyle.isEmpty
            && strengths.isEmpty
            && struggles.isEmpty
            && preferredHelp.isEmpty
    }

    /// First-person write-back text for EverOS durable memory.
    func everOSWriteBackMessage() -> String {
        """
        Here is my ideal learner profile (structured by StudyFlow):
        learningStyle: \(learningStyle)
        strengths: \(strengths.joined(separator: "; "))
        struggles: \(struggles.joined(separator: "; "))
        preferredHelp: \(preferredHelp)
        motivationTriggers: \(motivationTriggers.joined(separator: "; "))
        subjectHints: \(subjectHints.joined(separator: "; "))
        confidence: \(String(format: "%.2f", confidence))
        summary: \(summary)
        evidenceNotes: \(evidenceNotes.joined(separator: "; "))
        Please treat this as my durable learner profile going forward.
        """
    }
}

/// Inputs gathered for Gemma profile synthesis.
struct ProfileSynthesisInput: Sendable {
    var userId: String
    var sessionId: String?
    var samplesSent: Int
    var everOSExplicitInfo: [String: String]
    var everOSImplicitTraits: [String: String]
    var episodeSnippets: [String]
    var profileSnippets: [String]
    var recentOCRExcerpts: [String]
    var intakeSource: LearnerProfileSource
}
