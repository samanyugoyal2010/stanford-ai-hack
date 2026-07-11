import Foundation
import AppKit

struct SceneSpec: Codable, Equatable {
    struct Object: Codable, Equatable, Identifiable { var id = UUID(); let name: String; let primitive: String; let position: [Double]; let scale: [Double]; let color: String }
    let objects: [Object]
    static let `default` = SceneSpec(objects: [Object(name: "Core", primitive: "box", position: [0, 0, 0], scale: [2.2, 0.7, 1.4], color: "#E8A878"), Object(name: "Anchor", primitive: "cylinder", position: [0, -1, 0], scale: [0.5, 1, 0.5], color: "#6D9DC5")])
}

struct OllamaClient {
    var baseURL = URL(string: "http://127.0.0.1:11434")!
    var model = ProcessInfo.processInfo.environment["LUNAR_OLLAMA_MODEL"] ?? "gemma4"

    func activeModel() async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: baseURL.appendingPathComponent("api/tags"))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let payload = try JSONDecoder().decode(TagsResponse.self, from: data)
        return payload.models.first?.name ?? model
    }

    func chat(prompt: String) async throws -> String {
        let request = try makeRequest(path: "api/chat", body: ["model": model, "messages": [["role": "user", "content": prompt]], "stream": false])
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ChatResponse.self, from: data).message.content
    }

    func inferScene(prompt: String) async throws -> SceneSpec {
        let request = try makeRequest(path: "api/generate", body: ["model": model, "prompt": prompt + " Return JSON only.", "format": "json", "stream": false])
        let (data, _) = try await URLSession.shared.data(for: request)
        let raw = try JSONDecoder().decode(GenerateResponse.self, from: data).response.data(using: .utf8) ?? Data()
        return try JSONDecoder().decode(SceneSpec.self, from: raw)
    }

    private func makeRequest(path: String, body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path)); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.httpBody = try JSONSerialization.data(withJSONObject: body); return request
    }
    private struct TagsResponse: Codable { let models: [Tag] }
    private struct Tag: Codable { let name: String }
    private struct ChatResponse: Codable { let message: Message }
    private struct Message: Codable { let content: String }
    private struct GenerateResponse: Codable { let response: String }
}
