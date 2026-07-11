import Foundation
import Observation

/// Vision Framework OCR manager backed by `OCRProcessingPipeline`.
@Observable
@MainActor
final class VisionOCRManager: VisionOCRProviding {
    private(set) var status: ServiceStatus = .notStarted

    private let pipeline: OCRProcessingPipeline

    init(pipeline: OCRProcessingPipeline = OCRProcessingPipeline()) {
        self.pipeline = pipeline
    }

    func start() async throws {
        AppLogger.shared.info("VisionOCRManager.start()", category: .vision)
        status = .idle
    }

    func stop() async {
        AppLogger.shared.info("VisionOCRManager.stop()", category: .vision)
        status = .stopped
    }

    func recognizeText(in frame: CapturedFrame) async throws -> OCRResult {
        status = .running
        do {
            let result = try await pipeline.process(frame: frame)
            status = .idle
            return result
        } catch {
            status = .failed(error.localizedDescription)
            throw error
        }
    }
}
