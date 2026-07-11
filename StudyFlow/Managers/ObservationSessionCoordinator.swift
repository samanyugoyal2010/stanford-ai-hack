import Foundation
import Observation

/// Orchestrates a learner-profile observation session:
/// ScreenCaptureKit → Vision OCR → EverOS ingest → flush → profile fetch.
@Observable
@MainActor
final class ObservationSessionCoordinator {
    private let screenCapture: ScreenCaptureManager
    private let visionOCR: VisionOCRManager
    private let remoteMemory: EverOSMemoryService
    private let database: SQLiteStore

    private(set) var isRunning = false
    private(set) var sessionId: String?
    private(set) var samplesSent = 0
    private(set) var lastError: String?
    private(set) var lastProfile: LearnerProfileSnapshot?

    /// Seconds between OCR/EverOS samples.
    var sampleIntervalSeconds: TimeInterval = 4
    /// Upload a screenshot keyframe every N text samples.
    var keyframeEveryNSamples: Int = 3

    private var loopTask: Task<Void, Never>?

    init(
        screenCapture: ScreenCaptureManager,
        visionOCR: VisionOCRManager,
        remoteMemory: EverOSMemoryService,
        database: SQLiteStore
    ) {
        self.screenCapture = screenCapture
        self.visionOCR = visionOCR
        self.remoteMemory = remoteMemory
        self.database = database
    }

    func startSession() async throws {
        guard !isRunning else { return }
        lastError = nil
        samplesSent = 0
        let newSessionId = "obs_\(UUID().uuidString.lowercased())"
        sessionId = newSessionId

        try await visionOCR.start()
        try await screenCapture.start()

        isRunning = true
        AppLogger.shared.info("Observation session started \(newSessionId)", category: .app)

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

        do {
            try await remoteMemory.flush(userId: userId, sessionId: sid)
            // Brief pause so extraction can settle.
            try await Task.sleep(nanoseconds: 1_500_000_000)
            if let profile = try await remoteMemory.fetchProfile(userId: userId) {
                var tagged = profile
                tagged.source = .observation
                lastProfile = tagged
                try? database.open()
                try? database.saveLearnerProfile(tagged)
                AppLogger.shared.info("Observation profile fetched", category: .ai)
                return tagged
            }
            return lastProfile
        } catch {
            lastError = error.localizedDescription
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
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    consecutiveEmpty += 1
                } else {
                    consecutiveEmpty = 0
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
                // Keep looping unless cancelled — transient OCR/network failures shouldn't kill the session.
            }

            // Avoid tight loop if capture never produces frames.
            if consecutiveEmpty > 30 {
                lastError = "No screen frames received. Check Screen Recording permission for StudyFlow."
            }
        }
    }
}
