import Foundation
import Observation

/// High-level EverOS integration used by observation and manual profile flows.
@Observable
@MainActor
final class EverOSMemoryService: RemoteMemoryProviding {
    private let client: EverOSClient
    private let uploader: EverOSObjectUploader

    /// Stable StudyFlow learner id persisted in UserDefaults.
    let userId: String

    init(client: EverOSClient, uploader: EverOSObjectUploader) {
        self.client = client
        self.uploader = uploader
        self.userId = Self.loadOrCreateUserId()
    }

    func addMessages(userId: String, sessionId: String?, messages: [EverOSMessage]) async throws {
        _ = try await client.addMemories(userId: userId, sessionId: sessionId, messages: messages)
        AppLogger.shared.info(
            "EverOS addMessages count=\(messages.count) session=\(sessionId ?? "nil")",
            category: .ai
        )
    }

    func flush(userId: String, sessionId: String?) async throws {
        let result = try await client.flush(userId: userId, sessionId: sessionId)
        AppLogger.shared.info(
            "EverOS flush status=\(result.status ?? "unknown")",
            category: .ai
        )
    }

    func fetchProfile(userId: String) async throws -> LearnerProfileSnapshot? {
        let data = try await client.getProfiles(userId: userId)
        guard let first = data.profiles?.first else {
            return nil
        }
        return LearnerProfileSnapshot.from(everOS: first, userId: userId, source: .remote)
    }

    func search(userId: String, query: String, memoryTypes: [String], topK: Int) async throws -> EverOSSearchResult {
        let data = try await client.search(
            userId: userId,
            query: query,
            memoryTypes: memoryTypes,
            topK: topK
        )
        let episodes = (data.episodes ?? []).compactMap { $0.summary ?? $0.episode ?? $0.subject }
        let profiles = (data.profiles ?? []).compactMap { item -> String? in
            let snap = LearnerProfileSnapshot.from(everOS: item, userId: userId, source: .remote)
            let lines = snap.displayLines
            return lines.isEmpty ? nil : lines.joined(separator: "; ")
        }
        return EverOSSearchResult(
            episodesSummary: episodes,
            profilesSummary: profiles,
            rawSnippet: (episodes + profiles).joined(separator: "\n")
        )
    }

    /// Uploads a JPEG keyframe and returns an EverOS image content item.
    func makeImageContentItem(jpegData: Data, name: String = "observation.jpg") async throws -> EverOSContentItem {
        let objectKey = try await uploader.uploadImage(data: jpegData, fileName: name, ext: "jpg")
        return .image(objectKey: objectKey, name: name, ext: "jpg")
    }

    private static let userDefaultsKey = "studyflow.everos.user_id"

    private static func loadOrCreateUserId() -> String {
        if let existing = UserDefaults.standard.string(forKey: userDefaultsKey), !existing.isEmpty {
            return existing
        }
        let created = "studyflow_\(UUID().uuidString.lowercased())"
        UserDefaults.standard.set(created, forKey: userDefaultsKey)
        return created
    }
}
