import Foundation

/// Prompt templates for Socratic-safe ideal learner profile synthesis.
enum ProfileSynthesisPrompt {
    static let systemRules = """
    You are StudyFlow's learner-profile synthesizer.
    Your job is ONLY to summarize how a student learns from evidence.
    Never solve homework, never give final answers, never invent clinical diagnoses.
    Prefer concrete study behaviors (e.g. "jumps between tabs", "rereads proofs").
    preferredHelp must favor Socratic hints / guiding questions over full solutions.
    If evidence is thin, lower confidence and keep arrays short — do not hallucinate.
    Return ONLY a single JSON object with exactly these keys:
    learningStyle (string),
    strengths (string array),
    struggles (string array),
    preferredHelp (string),
    motivationTriggers (string array),
    subjectHints (string array),
    confidence (number 0 to 1),
    summary (string),
    evidenceNotes (string array).
    """

    static func userPrompt(for input: ProfileSynthesisInput) -> String {
        let explicit = input.everOSExplicitInfo
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
        let implicit = input.everOSImplicitTraits
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
        let episodes = input.episodeSnippets.prefix(8).joined(separator: "\n- ")
        let profiles = input.profileSnippets.prefix(5).joined(separator: "\n- ")
        let ocr = input.recentOCRExcerpts.prefix(10).map { String($0.prefix(400)) }.joined(separator: "\n---\n")

        return """
        \(systemRules)

        Intake source: \(input.intakeSource.rawValue)
        Session: \(input.sessionId ?? "none")
        Observation samples sent: \(input.samplesSent)

        EverOS explicit_info:
        \(explicit.isEmpty ? "(none)" : explicit)

        EverOS implicit_traits:
        \(implicit.isEmpty ? "(none)" : implicit)

        EverOS episode snippets:
        \(episodes.isEmpty ? "(none)" : "- \(episodes)")

        EverOS profile search snippets:
        \(profiles.isEmpty ? "(none)" : "- \(profiles)")

        Recent on-screen OCR excerpts:
        \(ocr.isEmpty ? "(none)" : ocr)

        Produce the IdealLearnerProfile JSON now.
        """
    }

    static func repairPrompt(invalidJSON: String) -> String {
        """
        \(systemRules)

        The following text was supposed to be valid IdealLearnerProfile JSON but failed to parse.
        Fix it into valid JSON matching the schema exactly. Return JSON only.

        Invalid output:
        \(invalidJSON.prefix(4000))
        """
    }
}
