import Foundation

/// Prompt templates for short spoken Socratic tutoring replies.
enum SocraticPrompt {
    static let systemRules = """
    You are StudyFlow, a fast spoken study coach.
    Reply in 1–2 short sentences suitable for text-to-speech.
    Use Socratic guidance: ask a pointed question or give a tiny hint.
    NEVER give final answers, full solutions, or long explanations.
    Never invent screen content you cannot see.
    Prefer the student's preferredHelp style when known.
    """

    static func build(
        context: StudyContext,
        idealProfile: IdealLearnerProfile?,
        everOSSnippets: String,
        conversationHistory: [(role: String, text: String)]
    ) -> String {
        let screen = String(context.screenText.prefix(900))
        let speech = context.recentSpeech
            .suffix(4)
            .map(\.text)
            .joined(separator: " | ")
        let history = conversationHistory
            .suffix(6)
            .map { "\($0.role): \($0.text)" }
            .joined(separator: "\n")

        let profileBlock: String
        if let ideal = idealProfile, !ideal.isEmpty {
            profileBlock = """
            Ideal learner profile:
            style: \(ideal.learningStyle)
            strengths: \(ideal.strengths.joined(separator: "; "))
            struggles: \(ideal.struggles.joined(separator: "; "))
            preferredHelp: \(ideal.preferredHelp)
            summary: \(ideal.summary)
            """
        } else {
            profileBlock = "Ideal learner profile: (none yet)"
        }

        return """
        \(systemRules)

        \(profileBlock)

        EverOS memory snippets:
        \(everOSSnippets.isEmpty ? "(none)" : String(everOSSnippets.prefix(600)))

        On-screen OCR (latest):
        \(screen.isEmpty ? "(none)" : screen)

        Recent student speech:
        \(speech.isEmpty ? "(none)" : speech)

        Activity: \(context.activitySummary)

        Conversation so far:
        \(history.isEmpty ? "(new session)" : history)

        Respond now as spoken StudyFlow coach (1–2 short sentences only).
        """
    }
}
