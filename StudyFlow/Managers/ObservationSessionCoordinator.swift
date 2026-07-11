import Foundation
import Observation

/// Orchestrates a learner-profile observation session:
/// ScreenCaptureKit → Vision OCR → EverOS ingest → flush → hybrid Gemma refine.
@Observable
@MainActor
final class ObservationSessionCoordinator {
    private let screenCapture: ScreenCaptureManager
    private let visionOCR: VisionOCRManager
    private let remoteMemory: EverOSMemoryService
    private let database: SQLiteStore
    private let hybridPipeline: HybridProfilePipeline
    private let log = PipelineActivityLog.shared

    private(set) var isRunning = false
    private(set) var sessionId: String?
    private(set) var samplesSent = 0
    private(set) var lastError: String?
    private(set) var lastProfile: LearnerProfileSnapshot?

    /// Seconds between OCR/EverOS samples.
    var sampleIntervalSeconds: TimeInterval = 4
    /// Upload a screenshot keyframe every N text samples.
    var keyframeEveryNSamples: Int = 3

    /// Ring buffer of recent non-empty OCR excerpts for Gemma synthesis.
    private(set) var recentOCRExcerpts: [String] = []
    private let maxOCRExcerpts = 10

    private var loopTask: Task<Void, Never>?

    init(
        screenCapture: ScreenCaptureManager,
        visionOCR: VisionOCRManager,
        remoteMemory: EverOSMemoryService,
        database: SQLiteStore,
        hybridPipeline: HybridProfilePipeline
    ) {
        self.screenCapture = screenCapture
        self.visionOCR = visionOCR
        self.remoteMemory = remoteMemory
        self.database = database
        self.hybridPipeline = hybridPipeline
    }

    func startSession() async throws {
        guard !isRunning else { return }
        lastError = nil
        samplesSent = 0
        recentOCRExcerpts = []
        let newSessionId = "obs_\(UUID().uuidString.lowercased())"
        sessionId = newSessionId

        log.info("Observe", "Session starting…")
        try await visionOCR.start()
        try await screenCapture.start()

        isRunning = true
        AppLogger.shared.info("Observation session started \(newSessionId)", category: .app)
        log.info("Observe", "Session running · id=\(newSessionId)")

        loopTask = Task { [weak self] in
            await self?.runLoop(sessionId: newSessionId)
        }
    }

    func stopSession() async throws -> LearnerProfileSnapshot? {
        isRunning = false
        loopTask?.cancel()
        loopTask = nil

        await screenCapture.stop()
        await visionOCR.stop()

        let userId = remoteMemory.userId
        let sid = sessionId
        let ocrCopy = recentOCRExcerpts
        let sampleCount = samplesSent

        do {
            log.info("Observe", "Stopping · flushing EverOS · samples=\(sampleCount)")
            try await remoteMemory.flush(userId: userId, sessionId: sid)
            try await Task.sleep(nanoseconds: 1_500_000_000)

            var base: LearnerProfileSnapshot?
            if let profile = try await remoteMemory.fetchProfile(userId: userId) {
                base = profile
                base?.source = .observation
                log.info("Observe", "EverOS profile fetched after stop")
            } else {
                log.info("Observe", "No EverOS profile yet after stop — will use OCR evidence")
            }

            let refined = await hybridPipeline.refine(
                baseProfile: base,
                sessionId: sid,
                samplesSent: sampleCount,
                recentOCRExcerpts: ocrCopy,
                intakeSource: .observation
            )
            lastProfile = refined
            log.info("Observe", "Stop complete · hasIdeal=\(refined?.ideal != nil)")
            return refined
        } catch {
            lastError = error.localizedDescription
            log.error("Observe", error.localizedDescription)
            throw error
        }
    }

    private func runLoop(sessionId: String) async {
        var consecutiveEmpty = 0
        while !Task.isCancelled && isRunning {
            do {
                try await Task.sleep(nanoseconds: UInt64(sampleIntervalSeconds * 1_000_000_000))
                guard isRunning, !Task.isCancelled else { break }

                guard let frame = await screenCapture.latestFrame() else {
                    consecutiveEmpty += 1
                    continue
                }

                let ocr = try await visionOCR.recognizeText(in: frame)
                let text = ocr.fullText
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    consecutiveEmpty += 1
                } else {
                    consecutiveEmpty = 0
                    appendOCRExcerpt(trimmed)
                }

                let shouldAttachImage =
                    keyframeEveryNSamples > 0
                    && samplesSent % keyframeEveryNSamples == 0
                    && frame.jpegData != nil

                let message: EverOSMessage
                if shouldAttachImage, let jpeg = frame.jpegData {
                    let imageItem = try await remoteMemory.makeImageContentItem(jpegData: jpeg)
                    message = ObservationMessageBuilder.makeMultimodalMessage(
                        ocrText: text,
                        frame: frame,
                        imageItem: imageItem
                    )
                } else {
                    message = ObservationMessageBuilder.makeTextMessage(ocrText: text, frame: frame)
                }

                try await remoteMemory.addMessages(
                    userId: remoteMemory.userId,
                    sessionId: sessionId,
                    messages: [message]
                )
                samplesSent += 1
            } catch is CancellationError {
                break
            } catch {
                lastError = error.localizedDescription
                AppLogger.shared.error("Observation loop error: \(error.localizedDescription)", category: .app)
            }

            if consecutiveEmpty > 30 {
                lastError = "No screen frames received. Check Screen Recording permission for StudyFlow."
            }
        }
    }

    private func appendOCRExcerpt(_ text: String) {
        recentOCRExcerpts.append(String(text.prefix(800)))
        if recentOCRExcerpts.count > maxOCRExcerpts {
            recentOCRExcerpts.removeFirst(recentOCRExcerpts.count - maxOCRExcerpts)
        }
    }
}
