import CoreGraphics
import Foundation

/// A recognized text region produced by the Apple Vision OCR pipeline.
struct OCRTextObservation: Identifiable, Sendable, Equatable {
    let id: UUID
    /// Recognized string for this region.
    let text: String
    /// Vision confidence in `[0, 1]`.
    let confidence: Float
    /// Normalized bounding box (origin bottom-left), if available.
    let boundingBox: CGRect?

    init(
        id: UUID = UUID(),
        text: String,
        confidence: Float,
        boundingBox: CGRect? = nil
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

/// Aggregated OCR output for one captured frame.
struct OCRResult: Identifiable, Sendable {
    let id: UUID
    /// Frame this OCR pass was run against.
    let frameID: UUID
    let timestamp: Date
    let observations: [OCRTextObservation]

    /// Convenience concatenation of all observation strings.
    var fullText: String {
        observations.map(\.text).joined(separator: "\n")
    }

    init(
        id: UUID = UUID(),
        frameID: UUID,
        timestamp: Date = Date(),
        observations: [OCRTextObservation] = []
    ) {
        self.id = id
        self.frameID = frameID
        self.timestamp = timestamp
        self.observations = observations
    }
}
