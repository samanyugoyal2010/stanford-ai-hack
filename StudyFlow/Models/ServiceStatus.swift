import Foundation

/// Lifecycle state shared by every StudyFlow subsystem shown on the dashboard.
///
/// Using one status type keeps ViewModels and UI cards consistent while individual
/// managers evolve independently behind their protocols.
enum ServiceStatus: Equatable, Sendable {
    /// The subsystem has never been started in this app session.
    case notStarted
    /// The subsystem is initialized and waiting to run.
    case idle
    /// The subsystem is actively processing.
    case running
    /// The subsystem was stopped cleanly.
    case stopped
    /// The subsystem failed; associated value is a user-facing reason.
    case failed(String)

    /// Short label suitable for dashboard status cards.
    var displayName: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .idle:
            return "Idle"
        case .running:
            return "Running"
        case .stopped:
            return "Stopped"
        case .failed(let message):
            return "Failed: \(message)"
        }
    }
}
