import Foundation

/// Placeholder SQLite-backed store with an in-memory learner profile cache.
///
/// Future work: open a file under Application Support and run migrations.
@MainActor
final class SQLiteStore: DatabaseProviding {
    private var isOpen = false
    private var memories: [MemoryEntry] = []
    private var cachedProfile: LearnerProfileSnapshot?

    func open() throws {
        AppLogger.shared.info("SQLiteStore.open() — in-memory placeholder", category: .database)
        isOpen = true
    }

    func close() {
        AppLogger.shared.info("SQLiteStore.close()", category: .database)
        isOpen = false
    }

    func insertMemory(_ entry: MemoryEntry) throws {
        guard isOpen else {
            throw StoreError.notOpen
        }
        memories.append(entry)
    }

    func fetchMemories(matching query: String, limit: Int) throws -> [MemoryEntry] {
        guard isOpen else {
            throw StoreError.notOpen
        }
        let lowered = query.lowercased()
        let filtered = memories.filter {
            query.isEmpty
                || $0.topic.lowercased().contains(lowered)
                || $0.content.lowercased().contains(lowered)
        }
        return Array(filtered.prefix(limit))
    }

    func saveLearnerProfile(_ profile: LearnerProfileSnapshot) throws {
        if !isOpen {
            try open()
        }
        cachedProfile = profile
        AppLogger.shared.info("Cached learner profile locally", category: .database)
    }

    func loadLearnerProfile() throws -> LearnerProfileSnapshot? {
        if !isOpen {
            try open()
        }
        return cachedProfile
    }

    enum StoreError: Error, LocalizedError {
        case notOpen

        var errorDescription: String? {
            switch self {
            case .notOpen:
                return "SQLiteStore is not open."
            }
        }
    }
}
