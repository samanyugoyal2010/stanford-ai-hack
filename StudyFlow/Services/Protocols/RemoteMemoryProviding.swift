import Foundation

/// App-facing remote memory boundary for EverOS Cloud.
@MainActor
protocol RemoteMemoryProviding: AnyObject {
    func addMessages(userId: String, sessionId: String?, messages: [EverOSMessage]) async throws
    func flush(userId: String, sessionId: String?) async throws
    func fetchProfile(userId: String) async throws -> LearnerProfileSnapshot?
    func search(userId: String, query: String, memoryTypes: [String], topK: Int) async throws -> EverOSSearchResult
}
