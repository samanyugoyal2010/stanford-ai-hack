import Foundation

/// Persistence boundary for StudyFlow data (memories, sessions, diagnostics).
///
/// Keeping SQLite behind a protocol allows in-memory fakes in unit tests.
/// Marked `@MainActor` so UI-facing managers can conform/use it under Swift 6
/// strict concurrency without crossing isolation domains.
@MainActor
protocol DatabaseProviding: AnyObject {
    func open() throws
    func close()
    func insertMemory(_ entry: MemoryEntry) throws
    func fetchMemories(matching query: String, limit: Int) throws -> [MemoryEntry]
    func saveLearnerProfile(_ profile: LearnerProfileSnapshot) throws
    func loadLearnerProfile() throws -> LearnerProfileSnapshot?
}
