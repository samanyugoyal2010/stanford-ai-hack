import Foundation

/// App-wide constants that are safe to share across modules.
enum AppConstants {
    /// Display name shown in the UI chrome.
    static let appName = "StudyFlow"

    /// Default local Ollama endpoint.
    static let ollamaBaseURL = URL(string: "http://127.0.0.1:11434")!

    /// EverOS Cloud API base URL.
    static let everOSBaseURL = URL(string: "https://api.evermind.ai")!

    /// Local Ollama model for ideal-profile synthesis.
    /// Defaults to Gemma 4 E2B QAT (~4.3GB) for memory-efficient Mac laptops.
    /// Override with `STUDYFLOW_OLLAMA_MODEL` if you prefer e4b / 12b.
    static var defaultModelName: String {
        if let env = ProcessInfo.processInfo.environment["STUDYFLOW_OLLAMA_MODEL"],
           !env.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return env.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "gemma4:e2b-it-qat"
    }

    /// Minimum macOS version StudyFlow targets.
    static let minimumMacOSVersion = "14.0"
}
