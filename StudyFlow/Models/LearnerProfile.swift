import Foundation

/// How a learner profile snapshot was produced.
enum LearnerProfileSource: String, Codable, Sendable {
    case observation
    case manual
    case upload
    case remote
    case hybrid
}

/// Pipeline stage for hybrid EverOS → Gemma synthesis (UI status line).
enum HybridSynthesisStatus: String, Sendable, Equatable {
    case idle
    case everOSExtracted
    case gemmaSynthesizing
    case ready
    case gemmaUnavailable

    var displayMessage: String {
        switch self {
        case .idle:
            return "Idle"
        case .everOSExtracted:
            return "EverOS extracted → preparing Gemma…"
        case .gemmaSynthesizing:
            return "EverOS extracted → Gemma synthesizing…"
        case .ready:
            return "Ready — ideal learner profile available"
        case .gemmaUnavailable:
            return "Gemma offline — showing EverOS raw traits"
        }
    }
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
    /// Structured ideal profile when hybrid Gemma synthesis succeeds.
    var ideal: IdealLearnerProfile?
    var synthesisStatus: HybridSynthesisStatus?

    var isEmpty: Bool {
        explicitInfo.isEmpty && implicitTraits.isEmpty && (ideal?.isEmpty ?? true)
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
        source: LearnerProfileSource = .remote,
        ideal: IdealLearnerProfile? = nil,
        synthesisStatus: HybridSynthesisStatus? = nil
    ) {
        self.id = id
        self.userId = userId
        self.explicitInfo = explicitInfo
        self.implicitTraits = implicitTraits
        self.rawJSON = rawJSON
        self.updatedAt = updatedAt
        self.source = source
        self.ideal = ideal
        self.synthesisStatus = synthesisStatus
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

// Manual Codable for HybridSynthesisStatus stored as raw string optionally.
extension HybridSynthesisStatus: Codable {}
