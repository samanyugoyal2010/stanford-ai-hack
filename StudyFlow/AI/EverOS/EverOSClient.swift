import Foundation

/// Low-level HTTP client for EverOS Cloud (`https://api.evermind.ai`).
actor EverOSClient {
    private let baseURL: URL
    private let session: URLSession
    private let credentials: EverOSCredentialStore
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL = AppConstants.everOSBaseURL,
        session: URLSession = .shared,
        credentials: EverOSCredentialStore = EverOSCredentialStore()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.credentials = credentials
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func addMemories(
        userId: String,
        sessionId: String?,
        messages: [EverOSMessage],
        asyncMode: Bool = true
    ) async throws -> EverOSAddResponseData {
        let body = EverOSAddMemoriesRequest(
            userId: userId,
            sessionId: sessionId,
            messages: messages.map(EverOSEncodableMessage.init(from:)),
            asyncMode: asyncMode
        )
        return try await post(
            path: "/api/v1/memories",
            body: body,
            as: EverOSDataEnvelope<EverOSAddResponseData>.self
        ).data ?? EverOSAddResponseData(taskId: nil, status: nil, messageCount: nil, message: nil)
    }

    func flush(userId: String, sessionId: String?) async throws -> EverOSFlushResponseData {
        let body = EverOSFlushRequest(userId: userId, sessionId: sessionId)
        return try await post(
            path: "/api/v1/memories/flush",
            body: body,
            as: EverOSDataEnvelope<EverOSFlushResponseData>.self
        ).data ?? EverOSFlushResponseData(status: nil, message: nil)
    }

    func getProfiles(userId: String, page: Int = 1, pageSize: Int = 5) async throws -> EverOSProfileGetData {
        let body = EverOSGetRequest(
            memoryType: "profile",
            filters: ["user_id": userId],
            page: page,
            pageSize: pageSize
        )
        return try await post(
            path: "/api/v1/memories/get",
            body: body,
            as: EverOSDataEnvelope<EverOSProfileGetData>.self
        ).data ?? EverOSProfileGetData(profiles: [], totalCount: 0, count: 0)
    }

    func search(
        userId: String,
        query: String,
        memoryTypes: [String],
        method: String = "hybrid",
        topK: Int = 5
    ) async throws -> EverOSSearchResponseData {
        let body = EverOSSearchRequest(
            query: query,
            filters: ["user_id": userId],
            method: method,
            memoryTypes: memoryTypes,
            topK: topK
        )
        return try await post(
            path: "/api/v1/memories/search",
            body: body,
            as: EverOSDataEnvelope<EverOSSearchResponseData>.self
        ).data ?? EverOSSearchResponseData(episodes: [], profiles: [])
    }

    func signObjects(_ objects: [EverOSSignObject]) async throws -> [EverOSSignedObject] {
        let body = EverOSSignRequest(objectList: objects)
        let response = try await post(
            path: "/api/v1/object/sign",
            body: body,
            as: EverOSDataEnvelope<EverOSSignResponseData>.self
        )
        guard let list = response.data?.objectList, !list.isEmpty else {
            throw EverOSClientError.emptySignResponse
        }
        return list
    }

    // MARK: - HTTP

    private func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        as: Response.Type
    ) async throws -> Response {
        guard let apiKey = credentials.apiKey() else {
            throw EverOSClientError.missingAPIKey
        }
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw EverOSClientError.invalidURL(path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(body)
        request.timeoutInterval = 60

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw EverOSClientError.httpStatus(-1, "No HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw EverOSClientError.httpStatus(http.statusCode, bodyText)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw EverOSClientError.decoding(error)
        }
    }
}
