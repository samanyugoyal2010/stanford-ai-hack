import Foundation

/// Content that EverOS accepts on a message — plain text or multimodal parts.
enum EverOSMessageContent: Sendable, Equatable {
    case text(String)
    case parts([EverOSContentItem])
}

/// A multimodal content item (text, image, etc.).
struct EverOSContentItem: Codable, Sendable, Equatable {
    var type: String
    var text: String?
    var uri: String?
    var name: String?
    var ext: String?

    static func text(_ value: String) -> EverOSContentItem {
        EverOSContentItem(type: "text", text: value, uri: nil, name: nil, ext: nil)
    }

    static func image(objectKey: String, name: String, ext: String) -> EverOSContentItem {
        EverOSContentItem(type: "image", text: nil, uri: objectKey, name: name, ext: ext)
    }
}

/// A single message for `POST /api/v1/memories`.
struct EverOSMessage: Sendable, Equatable {
    var role: String
    var timestamp: Int64
    var content: EverOSMessageContent

    static func user(text: String, at date: Date = Date()) -> EverOSMessage {
        EverOSMessage(
            role: "user",
            timestamp: Int64(date.timeIntervalSince1970 * 1000),
            content: .text(text)
        )
    }

    static func user(parts: [EverOSContentItem], at date: Date = Date()) -> EverOSMessage {
        EverOSMessage(
            role: "user",
            timestamp: Int64(date.timeIntervalSince1970 * 1000),
            content: .parts(parts)
        )
    }
}

// MARK: - Request / response envelopes

struct EverOSAddMemoriesRequest: Encodable {
    let userId: String
    let sessionId: String?
    let messages: [EverOSEncodableMessage]
    let asyncMode: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sessionId = "session_id"
        case messages
        case asyncMode = "async_mode"
    }
}

struct EverOSEncodableMessage: Encodable {
    let role: String
    let timestamp: Int64
    let content: EverOSEncodableContent

    init(from message: EverOSMessage) {
        role = message.role
        timestamp = message.timestamp
        switch message.content {
        case .text(let string):
            content = .string(string)
        case .parts(let items):
            content = .items(items)
        }
    }
}

enum EverOSEncodableContent: Encodable {
    case string(String)
    case items([EverOSContentItem])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .items(let items):
            try container.encode(items)
        }
    }
}

struct EverOSFlushRequest: Encodable {
    let userId: String
    let sessionId: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sessionId = "session_id"
    }
}

struct EverOSGetRequest: Encodable {
    let memoryType: String
    let filters: [String: String]
    let page: Int
    let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case memoryType = "memory_type"
        case filters
        case page
        case pageSize = "page_size"
    }
}

struct EverOSSearchRequest: Encodable {
    let query: String
    let filters: [String: String]
    let method: String
    let memoryTypes: [String]
    let topK: Int

    enum CodingKeys: String, CodingKey {
        case query
        case filters
        case method
        case memoryTypes = "memory_types"
        case topK = "top_k"
    }
}

struct EverOSSignRequest: Encodable {
    let objectList: [EverOSSignObject]

    enum CodingKeys: String, CodingKey {
        case objectList
    }
}

struct EverOSSignObject: Encodable {
    let fileId: String
    let fileName: String
    let fileType: String
}

struct EverOSDataEnvelope<T: Decodable>: Decodable {
    let data: T?
}

struct EverOSAddResponseData: Decodable {
    let taskId: String?
    let status: String?
    let messageCount: Int?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case status
        case messageCount = "message_count"
        case message
    }
}

struct EverOSFlushResponseData: Decodable {
    let status: String?
    let message: String?
}

struct EverOSProfileGetData: Decodable {
    let profiles: [EverOSProfileItem]?
    let totalCount: Int?
    let count: Int?

    enum CodingKeys: String, CodingKey {
        case profiles
        case totalCount = "total_count"
        case count
    }
}

struct EverOSProfileItem: Decodable {
    let id: String?
    let userId: String?
    let groupId: String?
    let profileData: EverOSProfileDataPayload?
    let scenario: String?
    let memcellCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case groupId = "group_id"
        case profileData = "profile_data"
        case scenario
        case memcellCount = "memcell_count"
    }
}

/// Flexible profile payload — EverOS may return nested objects or strings.
struct EverOSProfileDataPayload: Decodable {
    let explicitInfo: [String: String]
    let implicitTraits: [String: String]
    let rawJSON: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let explicit = Self.decodeStringMap(container, key: "explicit_info")
        let implicit = Self.decodeStringMap(container, key: "implicit_traits")
        explicitInfo = explicit
        implicitTraits = implicit

        var raw: [String: [String: String]] = [:]
        if !explicit.isEmpty { raw["explicit_info"] = explicit }
        if !implicit.isEmpty { raw["implicit_traits"] = implicit }
        if let data = try? JSONSerialization.data(withJSONObject: raw),
           let string = String(data: data, encoding: .utf8) {
            rawJSON = string
        } else {
            rawJSON = "{}"
        }
    }

    private static func decodeStringMap(
        _ container: KeyedDecodingContainer<DynamicCodingKey>,
        key: String
    ) -> [String: String] {
        let codingKey = DynamicCodingKey(key)
        if let dict = try? container.decode([String: EverOSLooseValue].self, forKey: codingKey) {
            return dict.mapValues(\.stringValue)
        }
        if let nested = try? container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: codingKey) {
            var result: [String: String] = [:]
            for nestedKey in nested.allKeys {
                if let value = try? nested.decode(EverOSLooseValue.self, forKey: nestedKey) {
                    result[nestedKey.stringValue] = value.stringValue
                }
            }
            return result
        }
        return [:]
    }
}

enum EverOSLooseValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else {
            self = .string("…")
        }
    }

    var stringValue: String {
        switch self {
        case .string(let value): return value
        case .number(let value): return String(value)
        case .bool(let value): return value ? "true" : "false"
        case .null: return ""
        }
    }
}

struct EverOSSearchResult: Sendable, Equatable {
    var episodesSummary: [String]
    var profilesSummary: [String]
    var rawSnippet: String
}

struct EverOSSearchResponseData: Decodable {
    let episodes: [EverOSEpisodeItem]?
    let profiles: [EverOSProfileItem]?
}

struct EverOSEpisodeItem: Decodable {
    let id: String?
    let summary: String?
    let subject: String?
    let episode: String?
}

struct EverOSSignResponseData: Decodable {
    let objectList: [EverOSSignedObject]?

    enum CodingKeys: String, CodingKey {
        case objectList
    }
}

struct EverOSSignedObject: Decodable {
    let fileId: String?
    let objectKey: String?
    let objectSignedInfo: EverOSSignedInfo?

    enum CodingKeys: String, CodingKey {
        case fileId
        case objectKey
        case objectSignedInfo
    }
}

struct EverOSSignedInfo: Decodable {
    let url: String?
    let fields: [String: String]?
}

// MARK: - Helpers

struct DynamicCodingKey: CodingKey, Hashable {
    var stringValue: String
    var intValue: Int?

    init(_ string: String) {
        stringValue = string
        intValue = nil
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

enum EverOSClientError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL(String)
    case httpStatus(Int, String)
    case decoding(Error)
    case emptySignResponse
    case uploadFailed(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "EVEROS_API_KEY is not set."
        case .invalidURL(let path):
            return "Invalid EverOS URL path: \(path)"
        case .httpStatus(let code, let body):
            return "EverOS HTTP \(code): \(body)"
        case .decoding(let error):
            return "EverOS decoding failed: \(error.localizedDescription)"
        case .emptySignResponse:
            return "EverOS object sign returned no objects."
        case .uploadFailed(let code):
            return "EverOS S3 upload failed with status \(code)."
        }
    }
}
