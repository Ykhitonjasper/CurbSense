import Foundation

enum RiskBand: String, Codable, CaseIterable, Hashable, Sendable {
    case routine
    case caution
    case stop
}

enum ObservationKind: String, Codable, CaseIterable, Hashable, Sendable {
    case visibleCondition
    case steeringFeel
    case sound
    case warningIndicator
}

enum EndingClass: String, Codable, CaseIterable, Hashable, Sendable {
    case safeActionComplete
    case stopAndWaitSafely
    case contactTrustedSupport
}

enum SessionStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case active
    case completed
    case abandoned
}

enum GlossaryCategory: String, Codable, CaseIterable, Hashable, Sendable {
    case sound
    case steeringFeel
    case visibleCondition
}

enum CatalogOrigin: String, Codable, CaseIterable, Hashable, Sendable {
    case catalog
    case recovery
    case history
}

struct RecoveryCard: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let trigger: ObservationKind
    let preparation: String
    let priority: Int
}

struct ActionPack: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let sessionID: String
    let headline: String
    let steps: [String]
    let generatedAt: Date
}

struct GlossaryEntry: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let term: String
    let category: GlossaryCategory
    let definition: String
    let examples: [String]
}

struct GraphValidation: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let isValid: Bool
    let issues: [String]
    let reachableNodeCount: Int
}

struct BranchProgress: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let visitedCount: Int
    let totalCount: Int
    let remainingNodeIDs: [String]
}

struct RunbookDetailPayload: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let runbookID: String
    let origin: CatalogOrigin
    let focusNodeID: String?
}

struct BranchMapPayload: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let sessionID: String
    let selectedNodeID: String?
    let showVisitedOnly: Bool
}

struct VerdictPayload: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let sessionID: String
    let endingClass: EndingClass
    let actionPackID: String
}

struct ActionPackPayload: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let actionPackID: String
    let sessionID: String
    let permitsSharing: Bool
}

struct HistoryDetailPayload: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let sessionID: String
    let runbookID: String
    let highlightedChoiceID: String?
    let showTimeline: Bool
}

struct DuplicatePayload: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let sourceRunbookID: String
    let suggestedTitle: String
    let copiedNodeCount: Int
}

struct RecoveryLibraryPayload: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let origin: CatalogOrigin
    let highlightedCardID: String?
    let showPreparationFirst: Bool
}

struct GlossaryPayload: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let category: GlossaryCategory?
    let highlightedTerm: String?
    let returnToActive: Bool
}
