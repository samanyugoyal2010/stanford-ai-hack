import Foundation
import Observation

/// A single pipeline event for the in-app activity log.
struct PipelineLogEntry: Identifiable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let stage: String
    let message: String
    let isError: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        stage: String,
        message: String,
        isError: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.stage = stage
        self.message = message
        self.isError = isError
    }

    var displayLine: String {
        let time = timestamp.formatted(date: .omitted, time: .standard)
        let mark = isError ? "ERR" : "OK"
        return "[\(time)] \(mark) \(stage) — \(message)"
    }
}

/// In-memory activity feed mirrored into Console.app via `AppLogger`.
@Observable
@MainActor
final class PipelineActivityLog {
    static let shared = PipelineActivityLog()

    private(set) var entries: [PipelineLogEntry] = []
    private let maxEntries = 200

    private init() {}

    func clear() {
        entries.removeAll()
    }

    func info(_ stage: String, _ message: String) {
        append(stage: stage, message: message, isError: false)
        AppLogger.shared.info("[\(stage)] \(message)", category: .pipeline)
    }

    func error(_ stage: String, _ message: String) {
        append(stage: stage, message: message, isError: true)
        AppLogger.shared.error("[\(stage)] \(message)", category: .pipeline)
    }

    private func append(stage: String, message: String, isError: Bool) {
        entries.append(PipelineLogEntry(stage: stage, message: message, isError: isError))
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }
}
