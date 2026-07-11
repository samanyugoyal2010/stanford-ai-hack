import Foundation
import Vision

/// Low-level Vision OCR processing helpers used by `VisionOCRManager`.
struct OCRProcessingPipeline: Sendable {
    /// Run OCR on a frame's JPEG data using `VNRecognizeTextRequest`.
    func process(frame: CapturedFrame) async throws -> OCRResult {
        guard let jpegData = frame.jpegData else {
            AppLogger.shared.debug("OCR skipped — frame \(frame.id) has no image data", category: .vision)
            return OCRResult(frameID: frame.id, observations: [])
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let request = VNRecognizeTextRequest()
                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = true

                    let handler = VNImageRequestHandler(data: jpegData, options: [:])
                    try handler.perform([request])

                    let observations = (request.results ?? []).compactMap { observation -> OCRTextObservation? in
                        guard let candidate = observation.topCandidates(1).first else { return nil }
                        return OCRTextObservation(
                            text: candidate.string,
                            confidence: candidate.confidence,
                            boundingBox: observation.boundingBox
                        )
                    }

                    continuation.resume(
                        returning: OCRResult(frameID: frame.id, observations: observations)
                    )
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
