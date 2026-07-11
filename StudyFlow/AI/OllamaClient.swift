import Foundation

enum OllamaError: Error, LocalizedError {
    case unreachable
    case badResponse(String)
    case emptyResponse
    case httpStatus(Int, String)

    var errorDescription: String? {
        switch self {
        case .unreachable:
            return "Ollama is unreachable at \(AppConstants.ollamaBaseURL.absoluteString). Start Ollama and pull your model."
        case .badResponse(let detail):
            return "Ollama returned a bad response: \(detail)"
        case .emptyResponse:
            return "Ollama returned an empty generation."
        case .httpStatus(let code, let body):
            return "Ollama HTTP \(code): \(body)"
        }
    }
}

/// HTTP client for the local Ollama API (`/api/tags`, `/api/generate`).
actor OllamaClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL = AppConstants.ollamaBaseURL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    /// Probes `GET /api/tags`.
    func isReachable() async -> Bool {
        guard let url = URL(string: "/api/tags", relativeTo: baseURL)?.absoluteURL else {
            return false
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3
        do {
            let (_, response) = try await session.data(for: request)
            return ((response as? HTTPURLResponse)?.statusCode ?? 0) == 200
        } catch {
            AppLogger.shared.debug("Ollama unreachable: \(error.localizedDescription)", category: .ai)
            return false
        }
    }

    /// Calls `POST /api/generate` with optional JSON format enforcement.
    func generate(
        prompt: String,
        model: String = AppConstants.defaultModelName,
        formatJSON: Bool = true
    ) async throws -> String {
        guard let url = URL(string: "/api/generate", relativeTo: baseURL)?.absoluteURL else {
            throw OllamaError.unreachable
        }

        var body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false
        ]
        if formatJSON {
            body["format"] = "json"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw OllamaError.unreachable
        }

        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(code) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw OllamaError.httpStatus(code, text)
        }

        do {
            let parsed = try decoder.decode(OllamaGenerateResponse.self, from: data)
            let trimmed = parsed.response.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw OllamaError.emptyResponse
            }
            return Self.stripCodeFences(trimmed)
        } catch let error as OllamaError {
            throw error
        } catch {
            throw OllamaError.badResponse(error.localizedDescription)
        }
    }

    /// Streams `POST /api/generate` with `stream: true` (NDJSON chunks). Spoken prose only — no JSON format.
    func generateStream(
        prompt: String,
        model: String = AppConstants.defaultModelName
    ) -> AsyncThrowingStream<String, Error> {
        let baseURL = self.baseURL
        let session = self.session

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let url = URL(string: "/api/generate", relativeTo: baseURL)?.absoluteURL else {
                        throw OllamaError.unreachable
                    }

                    let body: [String: Any] = [
                        "model": model,
                        "prompt": prompt,
                        "stream": true
                    ]

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    request.timeoutInterval = 120

                    let (bytes, response): (URLSession.AsyncBytes, URLResponse)
                    do {
                        (bytes, response) = try await session.bytes(for: request)
                    } catch {
                        throw OllamaError.unreachable
                    }

                    let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                    guard (200...299).contains(code) else {
                        throw OllamaError.httpStatus(code, "stream start failed")
                    }

                    var lineData = Data()
                    for try await byte in bytes {
                        if Task.isCancelled { break }
                        if byte == UInt8(ascii: "\n") {
                            if !lineData.isEmpty {
                                if let chunk = Self.parseStreamLine(lineData) {
                                    continuation.yield(chunk)
                                }
                                lineData = Data()
                            }
                        } else {
                            lineData.append(byte)
                        }
                    }
                    if !lineData.isEmpty, let chunk = Self.parseStreamLine(lineData) {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private static func parseStreamLine(_ data: Data) -> String? {
        guard let parsed = try? JSONDecoder().decode(OllamaStreamChunk.self, from: data) else {
            return nil
        }
        let piece = parsed.response
        return piece.isEmpty ? nil : piece
    }

    private static func stripCodeFences(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            result = result.replacingOccurrences(of: "```json", with: "")
            result = result.replacingOccurrences(of: "```", with: "")
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return result
    }
}

private struct OllamaGenerateResponse: Decodable {
    let response: String
}

private struct OllamaStreamChunk: Decodable {
    let response: String
    let done: Bool?
}
