import CoreGraphics
import CoreImage
import CoreVideo
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// A single screen frame captured for downstream Vision OCR and EverOS upload.
struct CapturedFrame: Identifiable, Sendable {
    let id: UUID
    /// Wall-clock time when the frame was captured.
    let timestamp: Date
    /// Pixel width of the captured image.
    let width: Int
    /// Pixel height of the captured image.
    let height: Int
    /// Optional display or window identifier the frame came from.
    let sourceDescription: String?
    /// JPEG-encoded image bytes for OCR and multimodal EverOS upload.
    let jpegData: Data?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        width: Int = 0,
        height: Int = 0,
        sourceDescription: String? = nil,
        jpegData: Data? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.width = width
        self.height = height
        self.sourceDescription = sourceDescription
        self.jpegData = jpegData
    }

    /// Builds a JPEG `CapturedFrame` from a CoreVideo pixel buffer.
    static func from(pixelBuffer: CVPixelBuffer, sourceDescription: String?) -> CapturedFrame? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        guard let jpegData = cgImage.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        return CapturedFrame(
            width: width,
            height: height,
            sourceDescription: sourceDescription,
            jpegData: jpegData
        )
    }
}

private extension CGImage {
    func jpegData(compressionQuality: CGFloat) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        CGImageDestinationAddImage(destination, self, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return data as Data
    }
}
