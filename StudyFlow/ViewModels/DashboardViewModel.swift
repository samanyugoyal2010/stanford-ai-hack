import Foundation
import Observation

/// Drives the main dashboard by surfacing subsystem statuses from the DI graph.
///
/// This milestone only displays placeholder statuses (all start as `.notStarted`).
/// Later iterations can start/stop the observation pipeline from here.
@Observable
@MainActor
final class DashboardViewModel {
    private let container: AppDependencyContainer

    init(container: AppDependencyContainer) {
        self.container = container
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
