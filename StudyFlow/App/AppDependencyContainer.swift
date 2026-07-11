import Foundation
import Observation
import SwiftUI

/// Composition root that constructs StudyFlow's pipeline and injects dependencies.
@Observable
@MainActor
final class AppDependencyContainer {
    // MARK: - Infrastructure

    let database: SQLiteStore
    let ollamaClient: OllamaClient
    let audioConfigurator: AudioCaptureConfigurator
    let ocrPipeline: OCRProcessingPipeline
    let everOSClient: EverOSClient
    let everOSUploader: EverOSObjectUploader

    // MARK: - Pipeline stages

    let screenCapture: ScreenCaptureManager
    let visionOCR: VisionOCRManager
    let speechRecognition: SpeechRecognitionManager
    let contextBuilder: ContextBuilder
    let behaviorAnalysis: BehaviorAnalysisEngine
    let memory: MemoryManager
    let remoteMemory: EverOSMemoryService
    let ai: GemmaService
    let voiceOutput: VoiceOutputManager
    let observationCoordinator: ObservationSessionCoordinator
    let manualProfileIngestor: ManualProfileIngestor

    init() {
        let database = SQLiteStore()
        let ollamaClient = OllamaClient()
        let audioConfigurator = AudioCaptureConfigurator()
        let ocrPipeline = OCRProcessingPipeline()
        let everOSClient = EverOSClient()
        let everOSUploader = EverOSObjectUploader(client: everOSClient)

        self.database = database
        self.ollamaClient = ollamaClient
        self.audioConfigurator = audioConfigurator
        self.ocrPipeline = ocrPipeline
        self.everOSClient = everOSClient
        self.everOSUploader = everOSUploader

        self.screenCapture = ScreenCaptureManager()
        self.visionOCR = VisionOCRManager(pipeline: ocrPipeline)
        self.speechRecognition = SpeechRecognitionManager(audioConfigurator: audioConfigurator)
        self.contextBuilder = ContextBuilder()
        self.behaviorAnalysis = BehaviorAnalysisEngine()
        self.memory = MemoryManager(store: database)
        let remoteMemory = EverOSMemoryService(client: everOSClient, uploader: everOSUploader)
        self.remoteMemory = remoteMemory
        self.ai = GemmaService(client: ollamaClient, remoteMemory: remoteMemory)
        self.voiceOutput = VoiceOutputManager()
        self.observationCoordinator = ObservationSessionCoordinator(
            screenCapture: screenCapture,
            visionOCR: visionOCR,
            remoteMemory: remoteMemory,
            database: database
        )
        self.manualProfileIngestor = ManualProfileIngestor(
            remoteMemory: remoteMemory,
            database: database
        )

        try? database.open()
        AppLogger.shared.info("AppDependencyContainer initialized", category: .app)
    }
}
