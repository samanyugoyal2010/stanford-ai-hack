import Foundation

/// Merges OCR and speech signals into a single `StudyContext` for downstream analysis.
@MainActor
protocol ContextBuilding: AnyObject {
    /// Current lifecycle status for dashboard / diagnostics.
    var status: ServiceStatus { get }

    /// Enable context aggregation.
    func start() async throws

    /// Disable context aggregation.
    func stop() async

    /// Build a context snapshot from the latest multimodal inputs.
    func buildContext(
        screenText: String,
        speech: [SpeechTranscript]
    ) async -> StudyContext
}
