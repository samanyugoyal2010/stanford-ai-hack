import Foundation
import Observation
import ScreenCaptureKit
import AppKit
import CoreMedia
import CoreVideo

/// ScreenCaptureKit capture manager.
///
/// Uses the system `SCContentSharingPicker` instead of
/// `CGRequestScreenCaptureAccess`, which re-shows the Screen Recording alert
/// even when StudyFlow already appears enabled in System Settings.
@Observable
@MainActor
final class ScreenCaptureManager: ScreenCapturing {
    private(set) var status: ServiceStatus = .notStarted
    private var latest: CapturedFrame?
    private var stream: SCStream?
    private let sampleHandler = ScreenCaptureSampleHandler()
    private var sourceDescription: String = "display"

    /// Reused after the user picks a display once this launch (no re-prompt).
    private var cachedFilter: SCContentFilter?
    private let pickerBridge = ContentSharingPickerBridge()

    func start() async throws {
        AppLogger.shared.info("ScreenCaptureManager.start()", category: .screenCapture)
        status = .idle

        do {
            let filter: SCContentFilter
            if let cachedFilter {
                filter = cachedFilter
            } else {
                filter = try await pickContentFilter()
                cachedFilter = filter
            }

            let config = makeStreamConfiguration(for: filter)
            sourceDescription = "picked-content"

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
            AppLogger.shared.info("Screen capture running", category: .screenCapture)
        } catch let error as CaptureError {
            status = .failed(error.localizedDescription)
            throw error
        } catch {
            status = .failed(error.localizedDescription)
            throw CaptureError.captureFailed(error.localizedDescription)
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

    // MARK: - Picker / fallback

    private func pickContentFilter() async throws -> SCContentFilter {
        do {
            return try await pickerBridge.pickDisplayFilter()
        } catch let error as CaptureError where error == .cancelled {
            throw error
        } catch {
            AppLogger.shared.debug(
                "Content picker failed (\(error.localizedDescription)); trying shareable content",
                category: .screenCapture
            )
            return try await filterFromShareableContent()
        }
    }

    private func filterFromShareableContent() async throws -> SCContentFilter {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else {
                throw CaptureError.noDisplay
            }
            sourceDescription = "display-\(display.displayID)"
            return SCContentFilter(display: display, excludingWindows: [])
        } catch let error as CaptureError {
            throw error
        } catch {
            openScreenRecordingSettings()
            throw CaptureError.permissionDenied
        }
    }

    private func makeStreamConfiguration(for filter: SCContentFilter) -> SCStreamConfiguration {
        let config = SCStreamConfiguration()
        let rect = filter.contentRect
        config.width = max(Int(rect.width), 1280)
        config.height = max(Int(rect.height), 720)
        config.minimumFrameInterval = CMTime(value: 1, timescale: 2)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true
        config.queueDepth = 3
        return config
    }

    private func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    enum CaptureError: Error, LocalizedError, Equatable {
        case noDisplay
        case permissionDenied
        case cancelled
        case captureFailed(String)

        var errorDescription: String? {
            switch self {
            case .noDisplay:
                return "No display available for screen capture."
            case .permissionDenied:
                return "Screen capture needs one approval: System Settings → Privacy & Security → Screen & System Audio Recording → enable StudyFlow, then quit and relaunch."
            case .cancelled:
                return "Screen share was cancelled."
            case .captureFailed(let detail):
                return "Screen capture failed: \(detail)"
            }
        }
    }
}

// MARK: - System content-sharing picker bridge

/// Presents `SCContentSharingPicker` and resumes with the chosen `SCContentFilter`.
@MainActor
final class ContentSharingPickerBridge: NSObject, SCContentSharingPickerObserver {
    private var continuation: CheckedContinuation<SCContentFilter, Error>?

    func pickDisplayFilter() async throws -> SCContentFilter {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<SCContentFilter, Error>) in
            continuation?.resume(throwing: ScreenCaptureManager.CaptureError.cancelled)
            continuation = cont

            let picker = SCContentSharingPicker.shared
            picker.add(self)
            picker.isActive = true
            // ObjC: presentPickerUsingContentStyle: — takes user straight into display pick.
            picker.present(using: .display)
        }
    }

    nonisolated func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didUpdateWith filter: SCContentFilter,
        for stream: SCStream?
    ) {
        Task { @MainActor in
            self.finish(with: .success(filter))
        }
    }

    nonisolated func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didCancelFor stream: SCStream?
    ) {
        Task { @MainActor in
            self.finish(with: .failure(ScreenCaptureManager.CaptureError.cancelled))
        }
    }

    nonisolated func contentSharingPickerStartDidFailWithError(_ error: Error) {
        Task { @MainActor in
            AppLogger.shared.error(
                "Content sharing picker failed: \(error.localizedDescription)",
                category: .screenCapture
            )
            self.finish(with: .failure(ScreenCaptureManager.CaptureError.permissionDenied))
        }
    }

    private func finish(with result: Result<SCContentFilter, Error>) {
        let picker = SCContentSharingPicker.shared
        picker.remove(self)
        picker.isActive = false
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
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
