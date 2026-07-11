import Foundation

/// Runs optical character recognition on captured screen frames.
///
/// Concrete implementations will use the Apple Vision framework.
@MainActor
protocol VisionOCRProviding: AnyObject {
    /// Current lifecycle status for dashboard / diagnostics.
    var status: ServiceStatus { get }

    /// Prepare OCR resources (models, queues). Safe to call more than once.
    func start() async throws

    /// Tear down OCR resources.
    func stop() async

    /// Recognize text in a captured frame. Placeholder returns an empty result.
    func recognizeText(in frame: CapturedFrame) async throws -> OCRResult
}
