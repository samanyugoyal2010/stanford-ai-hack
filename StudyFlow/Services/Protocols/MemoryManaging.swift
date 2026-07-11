import Foundation

/// Stores and retrieves long-lived study memories used to personalize guidance.
@MainActor
protocol MemoryManaging: AnyObject {
    /// Current lifecycle status for dashboard / diagnostics.
    var status: ServiceStatus { get }

    /// Open memory storage and load session state.
    func start() async throws

    /// Flush and close memory storage.
    func stop() async

    /// Persist a new memory entry.
    func save(_ entry: MemoryEntry) async throws

    /// Fetch memories relevant to a topic query (placeholder may return empty).
    func recall(matching query: String, limit: Int) async throws -> [MemoryEntry]
}
