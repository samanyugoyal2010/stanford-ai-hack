import Foundation

/// How a learner profile snapshot was produced.
enum LearnerProfileSource: String, Codable, Sendable {
    case observation
    case manual
    case upload
    case remote
}

/// Local view of an EverOS user profile for StudyFlow UI and Gemma context.
struct LearnerProfileSnapshot: Identifiable, Sendable, Equatable, Codable {
    var id: UUID
    var userId: String
    var explicitInfo: [String: String]
    var implicitTraits: [String: String]
    var rawJSON: String
    var updatedAt: Date
    var source: LearnerProfileSource

    var isEmpty: Bool {
        explicitInfo.isEmpty && implicitTraits.isEmpty
    }

    var displayLines: [String] {
        var lines: [String] = []
        for (key, value) in explicitInfo.sorted(by: { $0.key < $1.key }) where !value.isEmpty {
            lines.append("\(key): \(value)")
        }
        for (key, value) in implicitTraits.sorted(by: { $0.key < $1.key }) where !value.isEmpty {
            lines.append("\(key): \(value)")
        }
        return lines
    }

    init(
        id: UUID = UUID(),
        userId: String,
        explicitInfo: [String: String] = [:],
        implicitTraits: [String: String] = [:],
        rawJSON: String = "{}",
        updatedAt: Date = Date(),
        source: LearnerProfileSource = .remote
    ) {
        self.id = id
        self.userId = userId
        self.explicitInfo = explicitInfo
        self.implicitTraits = implicitTraits
        self.rawJSON = rawJSON
        self.updatedAt = updatedAt
        self.source = source
    }

    static func from(everOS item: EverOSProfileItem, userId: String, source: LearnerProfileSource) -> LearnerProfileSnapshot {
        let payload = item.profileData
        return LearnerProfileSnapshot(
            userId: item.userId ?? userId,
            explicitInfo: payload?.explicitInfo ?? [:],
            implicitTraits: payload?.implicitTraits ?? [:],
            rawJSON: payload?.rawJSON ?? "{}",
            source: source
        )
    }
}
