import Foundation
import Observation

/// Drives the main dashboard: subsystem statuses plus Start/Stop for observation + voice agent.
@Observable
@MainActor
final class DashboardViewModel {
    private let container: AppDependencyContainer

    private(set) var isStarting = false
    private(set) var lastError: String?
    private(set) var ollamaReady: Bool?

    init(container: AppDependencyContainer) {
        self.container = container
    }

    /// True while listening chrome / voice session is active (shared with menu-bar Stop).
    var isSessionActive: Bool {
        container.sessionChrome.isListeningChromeActive
    }

    var screenCaptureStatus: ServiceStatus {
        container.screenCapture.status
    }

    var visionStatus: ServiceStatus {
        container.visionOCR.status
    }

    var speechStatus: ServiceStatus {
        container.speechRecognition.status
    }

    var aiStatus: ServiceStatus {
        container.ai.status
    }

    var memoryStatus: ServiceStatus {
        container.memory.status
    }

    var agentPhase: VoiceAgentPhase {
        container.voiceAgent.phase
    }

    var lastUserUtterance: String {
        container.voiceAgent.lastUserUtterance
    }

    var lastAgentReply: String {
        container.voiceAgent.lastAgentReply
    }

    var samplesSent: Int {
        container.observationCoordinator.samplesSent
    }

    /// Card models bound by `DashboardView`.
    var statusCards: [StatusCardModel] {
        [
            StatusCardModel(title: "Screen Capture Status", status: screenCaptureStatus),
            StatusCardModel(title: "Vision Status", status: visionStatus),
            StatusCardModel(title: "Speech Recognition Status", status: speechStatus),
            StatusCardModel(title: "AI Status", status: aiStatus),
            StatusCardModel(title: "Memory Status", status: memoryStatus)
        ]
    }

    func refreshOllamaStatus() async {
        ollamaReady = await container.ollamaClient.isReachable()
    }

    func startSession() async {
        guard !isSessionActive, !isStarting else { return }
        isStarting = true
        lastError = nil
        defer { isStarting = false }

        let reachable = await container.ollamaClient.isReachable()
        ollamaReady = reachable
        guard reachable else {
            lastError = "Ollama is offline. Start Ollama and pull \(AppConstants.defaultModelName)."
            return
        }

        do {
            try await container.observationCoordinator.startSession()
            try await container.voiceAgent.start()
            container.sessionChrome.enterListeningMode()
        } catch {
            lastError = error.localizedDescription
            await container.voiceAgent.stop()
            _ = try? await container.observationCoordinator.stopSession(extractProfile: false)
            container.sessionChrome.isListeningChromeActive = false
        }
    }

    func stopSession() async {
        guard isSessionActive || container.voiceAgent.isRunning || container.observationCoordinator.isRunning else {
            return
        }
        lastError = nil
        await container.sessionChrome.stopListeningSession(
            voiceAgent: container.voiceAgent,
            observation: container.observationCoordinator
        )
    }
}

/// Lightweight value type for one dashboard status card.
struct StatusCardModel: Identifiable, Equatable {
    let id: String
    let title: String
    let status: ServiceStatus

    init(title: String, status: ServiceStatus) {
        self.id = title
        self.title = title
        self.status = status
    }
}
