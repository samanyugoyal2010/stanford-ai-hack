import Foundation

/// A durable or in-session memory item used to personalize Socratic guidance.
///
/// Memory Manager will persist these via SQLite in a later milestone.
struct MemoryEntry: Identifiable, Sendable, Equatable {
    let id: UUID
    let createdAt: Date
    /// Topic or subject tag (e.g. `calculus`, `chemistry`).
    let topic: String
    /// Stored content — misconceptions, progress notes, preferences, etc.
    let content: String
    /// Optional importance weight for retrieval ranking.
    let importance: Double

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        topic: String,
        content: String,
        importance: Double = 0.5
    ) {
        self.id = id
        self.createdAt = createdAt
        self.topic = topic
        self.content = content
        self.importance = importance
    }
}
