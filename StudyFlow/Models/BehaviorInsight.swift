import Foundation

/// High-level interpretation of student study behavior derived from context.
///
/// Examples of future insights: stuck on a problem, rapid tab switching,
/// passive reading, or asking for direct answers.
struct BehaviorInsight: Identifiable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    /// Short machine-friendly label (e.g. `stuck`, `exploring`).
    let category: String
    /// Human-readable explanation for logging and future UI.
    let summary: String
    /// Relative confidence in `[0, 1]`.
    let confidence: Double

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        category: String,
        summary: String,
        confidence: Double = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.summary = summary
        self.confidence = confidence
    }
}
