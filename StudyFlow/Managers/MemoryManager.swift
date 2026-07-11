import Foundation
import Observation

/// Session and long-term memory facade over the SQLite store.
///
/// Future work: embeddings / keyword retrieval, forgetting policies, and linking
/// memories to subjects and sessions for personalized Socratic prompts.
@Observable
@MainActor
final class MemoryManager: MemoryManaging {
    private(set) var status: ServiceStatus = .notStarted

    private let store: any DatabaseProviding

    init(store: any DatabaseProviding) {
        self.store = store
    }

    func start() async throws {
        AppLogger.shared.info("MemoryManager.start() — placeholder store", category: .memory)
        try store.open()
        status = .idle
    }

    func stop() async {
        AppLogger.shared.info("MemoryManager.stop()", category: .memory)
        store.close()
        status = .stopped
    }

    func save(_ entry: MemoryEntry) async throws {
        try store.insertMemory(entry)
    }

    func recall(matching query: String, limit: Int) async throws -> [MemoryEntry] {
        try store.fetchMemories(matching: query, limit: limit)
    }
}
