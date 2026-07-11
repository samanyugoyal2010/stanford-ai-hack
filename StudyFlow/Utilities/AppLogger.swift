import Foundation
import os

/// Lightweight logging facade used across StudyFlow modules.
///
/// Prefer this over `print` so categories can be filtered in Console.app.
final class AppLogger: Sendable {
    static let shared = AppLogger()

    enum Category: String, Sendable {
        case app
        case screenCapture
        case vision
        case speech
        case context
        case behavior
        case memory
        case ai
        case voice
        case audio
        case database
        case ui
        case pipeline
        case everos
        case ollama
    }

    private let subsystem = Bundle.main.bundleIdentifier ?? "com.studyflow.app"

    private init() {}

    func info(_ message: String, category: Category) {
        Logger(subsystem: subsystem, category: category.rawValue).info("\(message, privacy: .public)")
    }

    func debug(_ message: String, category: Category) {
        Logger(subsystem: subsystem, category: category.rawValue).debug("\(message, privacy: .public)")
    }

    func error(_ message: String, category: Category) {
        Logger(subsystem: subsystem, category: category.rawValue).error("\(message, privacy: .public)")
    }
}
