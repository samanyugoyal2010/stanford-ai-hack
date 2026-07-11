import Foundation

/// Uses local Gemma (Ollama) to turn EverOS evidence into an `IdealLearnerProfile`.
@MainActor
final class LearnerProfileSynthesizer {
    private let ollama: OllamaClient
    private let decoder = JSONDecoder()
    private let log = PipelineActivityLog.shared

    init(ollama: OllamaClient) {
        self.ollama = ollama
    }

    func synthesize(from input: ProfileSynthesisInput) async throws -> IdealLearnerProfile {
        log.info("Ollama", "Checking reachability at \(AppConstants.ollamaBaseURL.absoluteString)…")
        guard await ollama.isReachable() else {
            log.error("Ollama", "Unreachable — is Ollama running? Model=\(AppConstants.defaultModelName)")
            throw OllamaError.unreachable
        }
        log.info("Ollama", "Reachable · model=\(AppConstants.defaultModelName)")

        let prompt = ProfileSynthesisPrompt.userPrompt(for: input)
        log.info("Gemma", "Generate JSON · promptChars=\(prompt.count)")
        let raw = try await ollama.generate(prompt: prompt, formatJSON: true)
        log.info("Gemma", "Raw response chars=\(raw.count)")

        if let profile = decodeProfile(from: raw) {
            log.info("Gemma", "Decoded IdealLearnerProfile on first pass")
            return profile
        }

        log.info("Gemma", "JSON decode failed — repair pass…")
        let repairedRaw = try await ollama.generate(
            prompt: ProfileSynthesisPrompt.repairPrompt(invalidJSON: raw),
            formatJSON: true
        )
        if let repaired = decodeProfile(from: repairedRaw) {
            log.info("Gemma", "Decoded IdealLearnerProfile after repair")
            return repaired
        }

        log.error("Gemma", "Could not decode IdealLearnerProfile after repair")
        throw OllamaError.badResponse("Could not decode IdealLearnerProfile JSON after repair.")
    }

    private func decodeProfile(from raw: String) -> IdealLearnerProfile? {
        guard let data = raw.data(using: .utf8) else { return nil }
        do {
            var profile = try decoder.decode(IdealLearnerProfile.self, from: data)
            profile.sanitize()
            return profile
        } catch {
            log.info("Gemma", "Decode error: \(error.localizedDescription)")
            return nil
        }
    }
}
