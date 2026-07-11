import Foundation
import Observation
import ScreenCaptureKit
import CoreMedia
import CoreVideo

/// ScreenCaptureKit-backed capture manager that publishes JPEG frames for OCR / EverOS.
@Observable
@MainActor
final class ScreenCaptureManager: ScreenCapturing {
    private(set) var status: ServiceStatus = .notStarted
    private var latest: CapturedFrame?
    private var stream: SCStream?
    private let sampleHandler = ScreenCaptureSampleHandler()
    private var sourceDescription: String = "display"

    func start() async throws {
        AppLogger.shared.info("ScreenCaptureManager.start()", category: .screenCapture)
        status = .idle

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else {
                status = .failed("No shareable display found")
                throw CaptureError.noDisplay
            }

            sourceDescription = "display-\(display.displayID)"
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.width = max(display.width, 1280)
            config.height = max(display.height, 720)
            config.minimumFrameInterval = CMTime(value: 1, timescale: 2) // up to 2 FPS; coordinator throttles further
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.showsCursor = true
            config.queueDepth = 3

            let stream = SCStream(filter: filter, configuration: config, delegate: sampleHandler)
            sampleHandler.onFrame = { [weak self] frame in
                Task { @MainActor in
                    self?.latest = frame
                }
            }
            sampleHandler.onFailure = { [weak self] message in
                Task { @MainActor in
                    self?.status = .failed(message)
                }
            }

            try stream.addStreamOutput(sampleHandler, type: .screen, sampleHandlerQueue: sampleHandler.queue)
            try await stream.startCapture()
            self.stream = stream
            status = .running
            AppLogger.shared.info("Screen capture running on \(sourceDescription)", category: .screenCapture)
        } catch {
            status = .failed(error.localizedDescription)
            throw error
        }
    }

    func stop() async {
        AppLogger.shared.info("ScreenCaptureManager.stop()", category: .screenCapture)
        if let stream {
            try? await stream.stopCapture()
        }
        stream = nil
        sampleHandler.onFrame = nil
        sampleHandler.onFailure = nil
        latest = nil
        status = .stopped
    }

    func latestFrame() async -> CapturedFrame? {
        latest
    }

    enum CaptureError: Error, LocalizedError {
        case noDisplay

        var errorDescription: String? {
            switch self {
            case .noDisplay:
                return "No display available for ScreenCaptureKit."
            }
        }
    }
}

/// Receives `SCStream` frames off the main actor and converts them to `CapturedFrame`.
final class ScreenCaptureSampleHandler: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    let queue = DispatchQueue(label: "com.studyflow.screen-capture")
    var onFrame: (@Sendable (CapturedFrame) -> Void)?
    var onFailure: (@Sendable (String) -> Void)?
    private var sourceDescription = "display"

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen else { return }
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        guard let frame = CapturedFrame.from(pixelBuffer: pixelBuffer, sourceDescription: sourceDescription) else {
            return
        }
        onFrame?(frame)
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        onFailure?(error.localizedDescription)
    }
}
