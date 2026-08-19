import Foundation

struct RunbookSnapshot: Codable {
    var id: String
    var title: String
    var summary: String
    var riskBand: RiskBand
    var durationMinutes: Int
    var supplyNames: [String]
    var startNodeID: String
    var isSeeded: Bool
    var sourceRunbookID: String?

    init(_ runbook: Runbook) {
        id = runbook.id
        title = runbook.title
        summary = runbook.summary
        riskBand = runbook.riskBand
        durationMinutes = runbook.durationMinutes
        supplyNames = runbook.supplyNames
        startNodeID = runbook.startNodeID
        isSeeded = runbook.isSeeded
        sourceRunbookID = runbook.sourceRunbookID
    }

    func makeRunbook() -> Runbook {
        Runbook(id: id, title: title, summary: summary, riskBand: riskBand, durationMinutes: durationMinutes, supplyNames: supplyNames, startNodeID: startNodeID, isSeeded: isSeeded, sourceRunbookID: sourceRunbookID)
    }
}

struct NodeSnapshot: Codable {
    var id: String
    var runbookID: String
    var sequenceIndex: Int
    var prompt: String
    var observationKind: ObservationKind
    var choiceIDs: [String]
    var choiceLabels: [String]
    var choiceTargetNodeIDs: [String]
    var endingClass: EndingClass?

    init(_ node: Node) {
        id = node.id
        runbookID = node.runbookID
        sequenceIndex = node.sequenceIndex
        prompt = node.prompt
        observationKind = node.observationKind
        choiceIDs = node.choiceIDs
        choiceLabels = node.choiceLabels
        choiceTargetNodeIDs = node.choiceTargetNodeIDs
        endingClass = node.endingClass
    }

    func makeNode() -> Node {
        Node(id: id, runbookID: runbookID, sequenceIndex: sequenceIndex, prompt: prompt, observationKind: observationKind, choiceIDs: choiceIDs, choiceLabels: choiceLabels, choiceTargetNodeIDs: choiceTargetNodeIDs, endingClass: endingClass)
    }
}

struct RunSessionSnapshot: Codable {
    var id: String
    var runbookID: String
    var currentNodeID: String
    var visitedNodeIDs: [String]
    var selectedChoiceIDs: [String]
    var status: SessionStatus
    var startedAt: Date
    var completedAt: Date?
    var endingClass: EndingClass?
    var actionPackID: String?

    init(_ session: RunSession) {
        id = session.id
        runbookID = session.runbookID
        currentNodeID = session.currentNodeID
        visitedNodeIDs = session.visitedNodeIDs
        selectedChoiceIDs = session.selectedChoiceIDs
        status = session.status
        startedAt = session.startedAt
        completedAt = session.completedAt
        endingClass = session.endingClass
        actionPackID = session.actionPackID
    }

    func makeSession() -> RunSession {
        RunSession(id: id, runbookID: runbookID, currentNodeID: currentNodeID, visitedNodeIDs: visitedNodeIDs, selectedChoiceIDs: selectedChoiceIDs, status: status, startedAt: startedAt, completedAt: completedAt, endingClass: endingClass, actionPackID: actionPackID)
    }
}

struct ActionPackSnapshot: Codable {
    var id: String
    var sessionID: String
    var headline: String
    var steps: [String]
    var generatedAt: Date

    init(_ actionPack: ActionPack) {
        id = actionPack.id
        sessionID = actionPack.sessionID
        headline = actionPack.headline
        steps = actionPack.steps
        generatedAt = actionPack.generatedAt
    }

    func makeActionPack() -> ActionPack {
        ActionPack(id: id, sessionID: sessionID, headline: headline, steps: steps, generatedAt: generatedAt)
    }
}

struct CurbSenseArchive: Codable {
    var runbooks: [RunbookSnapshot]
    var nodes: [NodeSnapshot]
    var sessions: [RunSessionSnapshot]
    var actionPacks: [ActionPackSnapshot]
    var nextDuplicateSequence: Int
    var nextSessionSequence: Int
    var onboardingComplete: Bool

    static func initialSeed() -> CurbSenseArchive {
        CurbSenseArchive(
            runbooks: CurbSenseSeedData.runbooks().map(RunbookSnapshot.init),
            nodes: CurbSenseSeedData.nodes().map(NodeSnapshot.init),
            sessions: CurbSenseSeedData.sessions().map(RunSessionSnapshot.init),
            actionPacks: CurbSenseSeedData.actionPacks().map(ActionPackSnapshot.init),
            nextDuplicateSequence: 1,
            nextSessionSequence: 7,
            onboardingComplete: false
        )
    }

    static func cleared() -> CurbSenseArchive {
        CurbSenseArchive(runbooks: [], nodes: [], sessions: [], actionPacks: [], nextDuplicateSequence: 1, nextSessionSequence: 1, onboardingComplete: false)
    }
}

final class CurbSenseArchiveStore {
    private let userDefaults: UserDefaults?
    private let storageKey: String
    private var archive: CurbSenseArchive

    init(userDefaults: UserDefaults?, storageKey: String, initialArchive: CurbSenseArchive) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        if let encoded = userDefaults?.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(CurbSenseArchive.self, from: encoded) {
            archive = decoded
        } else {
            archive = initialArchive
            if let encoded = try? JSONEncoder().encode(initialArchive) {
                userDefaults?.set(encoded, forKey: storageKey)
            }
        }
    }

    static func persistent() -> CurbSenseArchiveStore {
        CurbSenseArchiveStore(userDefaults: .standard, storageKey: "curbsense.local.archive.v1", initialArchive: .initialSeed())
    }

    static func memory() -> CurbSenseArchiveStore {
        CurbSenseArchiveStore(userDefaults: nil, storageKey: "curbsense.preview.archive", initialArchive: .initialSeed())
    }

    func read() -> CurbSenseArchive {
        archive
    }

    @discardableResult
    func update(_ change: (inout CurbSenseArchive) -> Void) -> Bool {
        change(&archive)
        return persist()
    }

    @discardableResult
    func reset() -> Bool {
        archive = .cleared()
        return persist()
    }

    private func persist() -> Bool {
        guard let userDefaults else { return true }
        guard let encoded = try? JSONEncoder().encode(archive) else { return false }
        userDefaults.set(encoded, forKey: storageKey)
        return true
    }
}
