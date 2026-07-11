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
    let profileSynthesizer: LearnerProfileSynthesizer

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
    let hybridPipeline: HybridProfilePipeline
    let observationCoordinator: ObservationSessionCoordinator
    let manualProfileIngestor: ManualProfileIngestor
    let voiceAgent: VoiceAgentCoordinator

    init() {
        let database = SQLiteStore()
        let ollamaClient = OllamaClient()
        let audioConfigurator = AudioCaptureConfigurator()
        let ocrPipeline = OCRProcessingPipeline()
        let everOSClient = EverOSClient()
        let everOSUploader = EverOSObjectUploader(client: everOSClient)
        let profileSynthesizer = LearnerProfileSynthesizer(ollama: ollamaClient)

        self.database = database
        self.ollamaClient = ollamaClient
        self.audioConfigurator = audioConfigurator
        self.ocrPipeline = ocrPipeline
        self.everOSClient = everOSClient
        self.everOSUploader = everOSUploader
        self.profileSynthesizer = profileSynthesizer

        let screenCapture = ScreenCaptureManager()
        let visionOCR = VisionOCRManager(pipeline: ocrPipeline)
        let speechRecognition = SpeechRecognitionManager(audioConfigurator: audioConfigurator)
        let contextBuilder = ContextBuilder()
        self.screenCapture = screenCapture
        self.visionOCR = visionOCR
        self.speechRecognition = speechRecognition
        self.contextBuilder = contextBuilder
        self.behaviorAnalysis = BehaviorAnalysisEngine()
        self.memory = MemoryManager(store: database)

        let remoteMemory = EverOSMemoryService(client: everOSClient, uploader: everOSUploader)
        self.remoteMemory = remoteMemory
        let ai = GemmaService(client: ollamaClient, remoteMemory: remoteMemory, database: database)
        let voiceOutput = VoiceOutputManager()
        self.ai = ai
        self.voiceOutput = voiceOutput

        let hybridPipeline = HybridProfilePipeline(
            remoteMemory: remoteMemory,
            synthesizer: profileSynthesizer,
            database: database
        )
        self.hybridPipeline = hybridPipeline

        let observationCoordinator = ObservationSessionCoordinator(
            screenCapture: screenCapture,
            visionOCR: visionOCR,
            remoteMemory: remoteMemory,
            database: database,
            hybridPipeline: hybridPipeline
        )
        self.observationCoordinator = observationCoordinator
        self.manualProfileIngestor = ManualProfileIngestor(
            remoteMemory: remoteMemory,
            database: database,
            hybridPipeline: hybridPipeline
        )

        self.voiceAgent = VoiceAgentCoordinator(
            speech: speechRecognition,
            voice: voiceOutput,
            ai: ai,
            contextBuilder: contextBuilder,
            observation: observationCoordinator,
            database: database
        )

        try? database.open()
        AppLogger.shared.info("AppDependencyContainer initialized", category: .app)
    }
}
