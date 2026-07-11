import Foundation

/// Captures the student's screen (or selected windows) for real-time study observation.
///
/// Concrete implementations will use ScreenCaptureKit. Callers depend only on this
/// protocol so capture can be mocked in tests.
@MainActor
protocol ScreenCapturing: AnyObject {
    /// Current lifecycle status for dashboard / diagnostics.
    var status: ServiceStatus { get }

    /// Begin capturing frames. Placeholder implementations do not request permissions yet.
    func start() async throws

    /// Stop capturing and release capture resources.
    func stop() async

    /// Returns the most recent frame, if any.
    func latestFrame() async -> CapturedFrame?
}
