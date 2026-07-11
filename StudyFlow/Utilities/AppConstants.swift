import Foundation

/// App-wide constants that are safe to share across modules.
enum AppConstants {
    /// Display name shown in the UI chrome.
    static let appName = "StudyFlow"

    /// Default local Ollama endpoint.
    static let ollamaBaseURL = URL(string: "http://127.0.0.1:11434")!

    /// EverOS Cloud API base URL.
    static let everOSBaseURL = URL(string: "https://api.evermind.ai")!

    /// Intended local model for Socratic guidance (not pulled in this skeleton).
    static let defaultModelName = "gemma4"

    /// Minimum macOS version StudyFlow targets.
    static let minimumMacOSVersion = "14.0"
}
