import Foundation

/// Thin HTTP client for the local Ollama API.
///
/// Future work: `/api/generate` and `/api/chat` against Gemma 4, streaming tokens,
/// health checks, and model pull status. No network calls in this skeleton.
actor OllamaClient {
    private let baseURL: URL

    init(baseURL: URL = AppConstants.ollamaBaseURL) {
        self.baseURL = baseURL
    }

    /// Placeholder health probe — always reports unavailable until wired.
    func isReachable() async -> Bool {
        AppLogger.shared.debug("OllamaClient.isReachable() stub at \(baseURL.absoluteString)", category: .ai)
        return false
    }

    /// Placeholder generation entry point. Returns an empty string.
    func generate(prompt: String, model: String = AppConstants.defaultModelName) async throws -> String {
        AppLogger.shared.info(
            "OllamaClient.generate stub — model=\(model), promptLength=\(prompt.count)",
            category: .ai
        )
        return ""
    }
}
